import { Body, Controller, Delete, Get, HttpCode, Param, ParseUUIDPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser, type AuthUser } from '../common/current-user.decorator.js';
import type { Comment, Project } from '../entities.js';
import { CreateCommentDto, CreateProjectDto, CreateTaskDto, UpdateProjectDto, UpdateTaskDto } from './dto.js';
import type { ProjectSummary } from './progress.js';
import { ProjectsService } from './projects.service.js';

@ApiTags('projects')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projects: ProjectsService) {}

  @Get()
  @ApiOperation({ summary: 'List my projects with progress' })
  list(@CurrentUser() user: AuthUser): Promise<ProjectSummary[]> {
    return this.projects.list(user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a project with the five standard phases' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateProjectDto): Promise<Project> {
    return this.projects.create(user.id, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Project detail: phases, tasks, comments' })
  get(@CurrentUser() user: AuthUser, @Param('id', ParseUUIDPipe) id: string): Promise<Project> {
    return this.projects.get(user.id, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Rename, describe or archive a project' })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateProjectDto,
  ): Promise<Project> {
    return this.projects.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  @ApiOperation({ summary: 'Delete a project and everything in it' })
  remove(@CurrentUser() user: AuthUser, @Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.projects.remove(user.id, id);
  }

  @Post(':id/phases/:phaseId/tasks')
  @ApiOperation({ summary: 'Add a task to a phase' })
  addTask(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('phaseId', ParseUUIDPipe) phaseId: string,
    @Body() dto: CreateTaskDto,
  ): Promise<Project> {
    return this.projects.addTask(user.id, id, phaseId, dto);
  }

  @Patch(':id/tasks/:taskId')
  @ApiOperation({ summary: 'Rename or toggle a task; phases advance automatically' })
  updateTask(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Body() dto: UpdateTaskDto,
  ): Promise<Project> {
    return this.projects.updateTask(user.id, id, taskId, dto);
  }

  @Delete(':id/tasks/:taskId')
  @ApiOperation({ summary: 'Remove a task' })
  removeTask(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('taskId', ParseUUIDPipe) taskId: string,
  ): Promise<Project> {
    return this.projects.removeTask(user.id, id, taskId);
  }

  @Post(':id/comments')
  @ApiOperation({ summary: 'Leave a comment on a project' })
  addComment(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateCommentDto,
  ): Promise<Comment> {
    return this.projects.addComment(user, id, dto);
  }
}
