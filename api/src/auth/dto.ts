import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'dana@studio.co.il' }) @IsEmail() email: string;
  @ApiProperty({ example: 'Dana Levi' }) @IsString() @MinLength(1) @MaxLength(80) name: string;
  @ApiProperty({ example: 'correct-horse-battery', minLength: 8 }) @IsString() @MinLength(8) @MaxLength(128) password: string;
}

export class LoginDto {
  @ApiProperty({ example: 'demo@milestone.app' }) @IsEmail() email: string;
  @ApiProperty({ example: 'demo1234' }) @IsString() @MinLength(1) password: string;
}

export class AuthResponseDto {
  @ApiProperty() accessToken: string;
  @ApiProperty({ example: { id: 'uuid', email: 'demo@milestone.app', name: 'Demo Client' } })
  user: { id: string; email: string; name: string };
}
