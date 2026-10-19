import { Injectable, Logger, type OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import bcrypt from 'bcryptjs';
import { ProjectsService } from './projects/projects.service.js';
import { UsersService } from './users/users.service.js';

export const DEMO_EMAIL = 'demo@milestone.app';
export const DEMO_PASSWORD = 'demo1234';

/** Creates a demo account with two projects on an empty database, so reviewers can log in at once. */
@Injectable()
export class SeedService implements OnApplicationBootstrap {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly users: UsersService,
    private readonly projects: ProjectsService,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (this.config.get('SEED_DEMO', 'true') !== 'true') return;
    if ((await this.users.count()) > 0) return;

    const demo = await this.users.create({
      email: DEMO_EMAIL,
      name: 'Demo Client',
      passwordHash: await bcrypt.hash(DEMO_PASSWORD, 10),
    });

    const fit = await this.projects.create(demo.id, {
      name: 'FitTrack',
      clientName: 'Herbalife Israel',
      description: 'Fitness coaching app for distributors. iOS and Android, Hebrew and English.',
    });
    const fitTasks = fit.phases.flatMap((p) => p.tasks);
    for (const task of fitTasks.slice(0, 10)) {
      await this.projects.updateTask(demo.id, fit.id, task.id, { done: true });
    }
    await this.projects.addComment({ id: demo.id, email: demo.email, name: demo.name }, fit.id, {
      body: 'Design looks great. Can we see the Hebrew RTL screens before sign-off?',
    });

    const keys = await this.projects.create(demo.id, {
      name: 'GetKey',
      clientName: 'GetKey Real Estate',
      description: 'Rentals without agency fees: listings, visits, digital lease.',
    });
    const keyTasks = keys.phases.flatMap((p) => p.tasks);
    for (const task of keyTasks.slice(0, 3)) {
      await this.projects.updateTask(demo.id, keys.id, task.id, { done: true });
    }

    this.logger.log(`Seeded demo account ${DEMO_EMAIL}`);
  }
}
