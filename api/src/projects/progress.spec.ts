import { derivePhaseStatuses, summarize } from './progress.js';
import type { Project } from '../entities.js';

const phase = (done: boolean[], order = 0) =>
  ({ order, tasks: done.map((d, i) => ({ done: d, order: i })) }) as never;

describe('derivePhaseStatuses', () => {
  it('activates the first phase of a fresh project', () => {
    expect(derivePhaseStatuses([phase([false, false]), phase([false])])).toEqual(['active', 'pending']);
  });

  it('moves the active phase forward when all its tasks are done', () => {
    expect(derivePhaseStatuses([phase([true, true]), phase([false]), phase([false])])).toEqual([
      'done',
      'active',
      'pending',
    ]);
  });

  it('never marks an empty phase as done', () => {
    expect(derivePhaseStatuses([phase([]), phase([false])])).toEqual(['active', 'pending']);
  });

  it('marks everything done when every task is done', () => {
    expect(derivePhaseStatuses([phase([true]), phase([true])])).toEqual(['done', 'done']);
  });
});

describe('summarize', () => {
  it('computes progress and the current phase', () => {
    const project = {
      id: 'p1',
      name: 'App',
      clientName: 'Client',
      description: '',
      status: 'active',
      createdAt: new Date(),
      updatedAt: new Date(),
      phases: [
        { key: 'discovery', title: 'Discovery', order: 0, status: 'done', tasks: [{ done: true, order: 0 }] },
        { key: 'specification', title: 'Spec', order: 1, status: 'active', tasks: [{ done: false, order: 0 }, { done: true, order: 1 }] },
      ],
    } as unknown as Project;
    const summary = summarize(project);
    expect(summary.doneTasks).toBe(2);
    expect(summary.totalTasks).toBe(3);
    expect(summary.progress).toBeCloseTo(0.667, 3);
    expect(summary.currentPhase).toEqual({ key: 'specification', title: 'Spec' });
  });
});
