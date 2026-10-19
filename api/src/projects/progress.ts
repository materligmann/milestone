import type { Phase, PhaseStatus, Project } from '../entities.js';

export interface ProjectSummary {
  id: string;
  name: string;
  clientName: string;
  description: string;
  status: Project['status'];
  progress: number;
  doneTasks: number;
  totalTasks: number;
  currentPhase: { key: Phase['key']; title: string } | null;
  createdAt: Date;
  updatedAt: Date;
}

/** Sort phases by order and their tasks by order, in place, and return them. */
export function sortPhases(phases: Phase[]): Phase[] {
  phases.sort((a, b) => a.order - b.order);
  for (const phase of phases) phase.tasks?.sort((a, b) => a.order - b.order);
  return phases;
}

/**
 * A phase is done when it has tasks and all of them are done.
 * The first phase that is not done is the active one; the rest wait.
 * Pure function: returns the statuses, does not touch the input.
 */
export function derivePhaseStatuses(phases: ReadonlyArray<Pick<Phase, 'tasks'>>): PhaseStatus[] {
  const statuses: PhaseStatus[] = [];
  let activeFound = false;
  for (const phase of phases) {
    const tasks = phase.tasks ?? [];
    const done = tasks.length > 0 && tasks.every((t) => t.done);
    if (done) {
      statuses.push('done');
    } else if (!activeFound) {
      statuses.push('active');
      activeFound = true;
    } else {
      statuses.push('pending');
    }
  }
  return statuses;
}

export function applyPhaseStatuses(phases: Phase[]): Phase[] {
  const statuses = derivePhaseStatuses(phases);
  phases.forEach((phase, i) => (phase.status = statuses[i]));
  return phases;
}

export function summarize(project: Project): ProjectSummary {
  const phases = sortPhases(project.phases ?? []);
  const tasks = phases.flatMap((p) => p.tasks ?? []);
  const doneTasks = tasks.filter((t) => t.done).length;
  const totalTasks = tasks.length;
  const current = phases.find((p) => p.status === 'active') ?? phases.at(-1) ?? null;
  return {
    id: project.id,
    name: project.name,
    clientName: project.clientName,
    description: project.description,
    status: project.status,
    progress: totalTasks === 0 ? 0 : Math.round((doneTasks / totalTasks) * 1000) / 1000,
    doneTasks,
    totalTasks,
    currentPhase: current ? { key: current.key, title: current.title } : null,
    createdAt: project.createdAt,
    updatedAt: project.updatedAt,
  };
}
