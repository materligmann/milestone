import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { AuthUser } from '../common/current-user.decorator.js';
import { Comment, Phase, Project, Task } from '../entities.js';
import type { CreateCommentDto, CreateProjectDto, CreateTaskDto, UpdateProjectDto, UpdateTaskDto } from './dto.js';
import { PHASE_TEMPLATE } from './phase-template.js';
import { applyPhaseStatuses, sortPhases, summarize, type ProjectSummary } from './progress.js';

const DETAIL_RELATIONS = { phases: { tasks: true }, comments: true } as const;

@Injectable()
export class ProjectsService {
  constructor(
    @InjectRepository(Project) private readonly projects: Repository<Project>,
    @InjectRepository(Phase) private readonly phases: Repository<Phase>,
    @InjectRepository(Task) private readonly tasks: Repository<Task>,
    @InjectRepository(Comment) private readonly comments: Repository<Comment>,
  ) {}

  async list(ownerId: string): Promise<ProjectSummary[]> {
    const projects = await this.projects.find({
      where: { ownerId },
      relations: { phases: { tasks: true } },
      order: { updatedAt: 'DESC' },
    });
    return projects.map(summarize);
  }

  async create(ownerId: string, dto: CreateProjectDto): Promise<Project> {
    const project = this.projects.create({
      ownerId,
      name: dto.name.trim(),
      clientName: dto.clientName.trim(),
      description: dto.description?.trim() ?? '',
      phases: PHASE_TEMPLATE.map((phase, order) =>
        this.phases.create({
          key: phase.key,
          title: phase.title,
          order,
          status: order === 0 ? 'active' : 'pending',
          tasks: phase.tasks.map((title, taskOrder) => this.tasks.create({ title, order: taskOrder })),
        }),
      ),
      comments: [],
    });
    const saved = await this.projects.save(project);
    return this.get(ownerId, saved.id);
  }

  async get(ownerId: string, id: string): Promise<Project> {
    const project = await this.projects.findOne({ where: { id }, relations: DETAIL_RELATIONS });
    if (!project) throw new NotFoundException('Project not found');
    if (project.ownerId !== ownerId) throw new ForbiddenException();
    sortPhases(project.phases);
    project.comments.sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    return project;
  }

  async update(ownerId: string, id: string, dto: UpdateProjectDto): Promise<Project> {
    const project = await this.get(ownerId, id);
    if (dto.name !== undefined) project.name = dto.name.trim();
    if (dto.clientName !== undefined) project.clientName = dto.clientName.trim();
    if (dto.description !== undefined) project.description = dto.description.trim();
    if (dto.status !== undefined) project.status = dto.status;
    await this.projects.save(project);
    return this.get(ownerId, id);
  }

  async remove(ownerId: string, id: string): Promise<void> {
    const project = await this.get(ownerId, id);
    await this.projects.remove(project);
  }

  async addTask(ownerId: string, projectId: string, phaseId: string, dto: CreateTaskDto): Promise<Project> {
    const project = await this.get(ownerId, projectId);
    const phase = project.phases.find((p) => p.id === phaseId);
    if (!phase) throw new NotFoundException('Phase not found');
    const order = (phase.tasks.at(-1)?.order ?? -1) + 1;
    await this.tasks.save(this.tasks.create({ phaseId: phase.id, title: dto.title.trim(), order }));
    return this.refresh(ownerId, projectId);
  }

  async updateTask(ownerId: string, projectId: string, taskId: string, dto: UpdateTaskDto): Promise<Project> {
    const project = await this.get(ownerId, projectId);
    const task = project.phases.flatMap((p) => p.tasks).find((t) => t.id === taskId);
    if (!task) throw new NotFoundException('Task not found');
    if (dto.title !== undefined) task.title = dto.title.trim();
    if (dto.done !== undefined) task.done = dto.done;
    await this.tasks.save(task);
    return this.refresh(ownerId, projectId);
  }

  async removeTask(ownerId: string, projectId: string, taskId: string): Promise<Project> {
    const project = await this.get(ownerId, projectId);
    const task = project.phases.flatMap((p) => p.tasks).find((t) => t.id === taskId);
    if (!task) throw new NotFoundException('Task not found');
    await this.tasks.remove(task);
    return this.refresh(ownerId, projectId);
  }

  async addComment(user: AuthUser, projectId: string, dto: CreateCommentDto): Promise<Comment> {
    await this.get(user.id, projectId);
    const comment = this.comments.create({
      projectId,
      authorId: user.id,
      authorName: user.name,
      body: dto.body.trim(),
    });
    const saved = await this.comments.save(comment);
    await this.projects.update(projectId, { updatedAt: new Date() });
    return saved;
  }

  /** Recompute phase statuses after a task change, persist them, and return the fresh project. */
  private async refresh(ownerId: string, projectId: string): Promise<Project> {
    const project = await this.get(ownerId, projectId);
    const before = project.phases.map((p) => p.status);
    applyPhaseStatuses(project.phases);
    const changed = project.phases.filter((p, i) => p.status !== before[i]);
    if (changed.length > 0) {
      await this.phases.save(changed.map(({ tasks: _tasks, project: _project, ...rest }) => rest as Phase));
    }
    await this.projects.update(projectId, { updatedAt: new Date() });
    return this.get(ownerId, projectId);
  }
}
