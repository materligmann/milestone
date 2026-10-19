import { ValidationPipe, type INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { AppModule } from '../src/app.module.js';

process.env.DATABASE_PATH = ':memory:';
process.env.JWT_SECRET = 'test-secret';
process.env.SEED_DEMO = 'false';

describe('Milestone API (e2e)', () => {
  let app: INestApplication<App>;
  let token: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  it('registers a user and returns a token', async () => {
    const res = await http()
      .post('/auth/register')
      .send({ email: 'dana@studio.co.il', name: 'Dana', password: 'password123' })
      .expect(201);
    expect(res.body.accessToken).toBeTypeOf('string');
    expect(res.body.user.email).toBe('dana@studio.co.il');
    token = res.body.accessToken;
  });

  it('rejects a duplicate email', async () => {
    await http()
      .post('/auth/register')
      .send({ email: 'Dana@studio.co.il', name: 'Dana', password: 'password123' })
      .expect(409);
  });

  it('rejects a bad password on login', async () => {
    await http().post('/auth/login').send({ email: 'dana@studio.co.il', password: 'wrong' }).expect(401);
  });

  it('refuses project routes without a token', async () => {
    await http().get('/projects').expect(401);
  });

  it('walks a project from creation to the second phase', async () => {
    const created = await http()
      .post('/projects')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'FitTrack', clientName: 'Herbalife' })
      .expect(201);

    const project = created.body;
    expect(project.phases).toHaveLength(5);
    expect(project.phases[0].status).toBe('active');
    expect(project.phases[1].status).toBe('pending');

    for (const task of project.phases[0].tasks) {
      await http()
        .patch(`/projects/${project.id}/tasks/${task.id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ done: true })
        .expect(200);
    }

    const list = await http().get('/projects').set('Authorization', `Bearer ${token}`).expect(200);
    expect(list.body).toHaveLength(1);
    expect(list.body[0].currentPhase.key).toBe('specification');
    expect(list.body[0].doneTasks).toBe(project.phases[0].tasks.length);

    const comment = await http()
      .post(`/projects/${project.id}/comments`)
      .set('Authorization', `Bearer ${token}`)
      .send({ body: 'Looks good' })
      .expect(201);
    expect(comment.body.authorName).toBe('Dana');

    const detail = await http().get(`/projects/${project.id}`).set('Authorization', `Bearer ${token}`).expect(200);
    expect(detail.body.phases[0].status).toBe('done');
    expect(detail.body.phases[1].status).toBe('active');
    expect(detail.body.comments).toHaveLength(1);
  });

  it('hides projects from other users', async () => {
    const other = await http()
      .post('/auth/register')
      .send({ email: 'other@studio.co.il', name: 'Other', password: 'password123' })
      .expect(201);
    const mine = await http().get('/projects').set('Authorization', `Bearer ${token}`).expect(200);
    await http()
      .get(`/projects/${mine.body[0].id}`)
      .set('Authorization', `Bearer ${other.body.accessToken}`)
      .expect(403);
  });
});
