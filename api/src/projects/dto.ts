import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateProjectDto {
  @ApiProperty({ example: 'FitTrack' }) @IsString() @MinLength(1) @MaxLength(80) name: string;
  @ApiProperty({ example: 'Herbalife Israel' }) @IsString() @MinLength(1) @MaxLength(80) clientName: string;
  @ApiPropertyOptional({ example: 'Fitness coaching app, iOS and Android, Hebrew and English.' })
  @IsOptional() @IsString() @MaxLength(2000) description?: string;
}

export class UpdateProjectDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MinLength(1) @MaxLength(80) name?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MinLength(1) @MaxLength(80) clientName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) description?: string;
  @ApiPropertyOptional({ enum: ['active', 'archived'] }) @IsOptional() @IsIn(['active', 'archived']) status?: 'active' | 'archived';
}

export class CreateTaskDto {
  @ApiProperty({ example: 'Push notifications' }) @IsString() @MinLength(1) @MaxLength(160) title: string;
}

export class UpdateTaskDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MinLength(1) @MaxLength(160) title?: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() done?: boolean;
}

export class CreateCommentDto {
  @ApiProperty({ example: 'Can we move the launch to after the holidays?' })
  @IsString() @MinLength(1) @MaxLength(2000) body: string;
}
