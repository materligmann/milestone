import type { PhaseKey } from '../entities.js';

/**
 * The five phases a software house walks a client through,
 * from the first meeting to the store launch. Each new project
 * starts with this checklist so the client sees the whole road.
 */
export const PHASE_TEMPLATE: ReadonlyArray<{ key: PhaseKey; title: string; tasks: readonly string[] }> = [
  {
    key: 'discovery',
    title: 'Discovery',
    tasks: ['Kick-off meeting', 'Goals and success metrics', 'Competitor review', 'Scope and budget agreed'],
  },
  {
    key: 'specification',
    title: 'Specification',
    tasks: ['User flows', 'Functional spec', 'Technical spec', 'Spec approved by client'],
  },
  {
    key: 'design',
    title: 'Design',
    tasks: ['Wireframes', 'UI kit (colors, type, components)', 'High-fidelity screens', 'Design approved by client'],
  },
  {
    key: 'development',
    title: 'Development',
    tasks: ['Backend and API', 'Mobile app', 'QA pass', 'Client acceptance'],
  },
  {
    key: 'launch',
    title: 'Launch',
    tasks: ['Store listings and screenshots', 'TestFlight / internal testing', 'Store review', 'Live'],
  },
];
