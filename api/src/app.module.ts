import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module.js';
import { Comment, Phase, Project, Task, User } from './entities.js';
import { HealthController } from './health.controller.js';
import { ProjectsModule } from './projects/projects.module.js';
import { SeedService } from './seed.service.js';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'better-sqlite3',
        database: config.get<string>('DATABASE_PATH', './data/milestone.sqlite'),
        entities: [User, Project, Phase, Task, Comment],
        synchronize: true,
      }),
    }),
    UsersModule,
    AuthModule,
    ProjectsModule,
  ],
  controllers: [HealthController],
  providers: [SeedService, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
