import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module.js';

async function bootstrap() {
  if (!process.env.JWT_SECRET) {
    process.env.JWT_SECRET = 'dev-only-secret-change-me';
    new Logger('Bootstrap').warn('JWT_SECRET is not set; using an insecure development secret');
  }

  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
  app.enableShutdownHooks();

  const document = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle('Milestone API')
      .setDescription(
        'Client portal for a software house: every project walks through Discovery, Specification, Design, Development and Launch. ' +
          'Log in with demo@milestone.app / demo1234 to explore.',
      )
      .setVersion('1.0')
      .addBearerAuth()
      .build(),
  );
  SwaggerModule.setup('docs', app, document, { customSiteTitle: 'Milestone API' });

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  new Logger('Bootstrap').log(`Milestone API listening on :${port}, docs at /docs`);
}
await bootstrap();
