import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export const PHASE_KEYS = ['discovery', 'specification', 'design', 'development', 'launch'] as const;
export type PhaseKey = (typeof PHASE_KEYS)[number];
export type PhaseStatus = 'pending' | 'active' | 'done';
export type ProjectStatus = 'active' | 'archived';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Index({ unique: true }) @Column() email: string;
  @Column() name: string;
  @Column({ select: false }) passwordHash: string;
  @CreateDateColumn() createdAt: Date;
}

@Entity('projects')
export class Project {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Index() @Column() ownerId: string;
  @Column() name: string;
  @Column() clientName: string;
  @Column({ default: '' }) description: string;
  @Column({ type: 'text', default: 'active' }) status: ProjectStatus;
  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
  @OneToMany(() => Phase, (phase) => phase.project, { cascade: true }) phases: Phase[];
  @OneToMany(() => Comment, (comment) => comment.project, { cascade: true }) comments: Comment[];
}

@Entity('phases')
export class Phase {
  @PrimaryGeneratedColumn('uuid') id: string;
  @ManyToOne(() => Project, (project) => project.phases, { onDelete: 'CASCADE' }) project: Project;
  @Index() @Column() projectId: string;
  @Column({ type: 'text' }) key: PhaseKey;
  @Column() title: string;
  @Column() order: number;
  @Column({ type: 'text', default: 'pending' }) status: PhaseStatus;
  @OneToMany(() => Task, (task) => task.phase, { cascade: true }) tasks: Task[];
}

@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid') id: string;
  @ManyToOne(() => Phase, (phase) => phase.tasks, { onDelete: 'CASCADE' }) phase: Phase;
  @Index() @Column() phaseId: string;
  @Column() title: string;
  @Column({ default: false }) done: boolean;
  @Column() order: number;
  @CreateDateColumn() createdAt: Date;
}

@Entity('comments')
export class Comment {
  @PrimaryGeneratedColumn('uuid') id: string;
  @ManyToOne(() => Project, (project) => project.comments, { onDelete: 'CASCADE' }) project: Project;
  @Index() @Column() projectId: string;
  @Column() authorId: string;
  @Column() authorName: string;
  @Column() body: string;
  @CreateDateColumn() createdAt: Date;
}
