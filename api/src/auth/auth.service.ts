import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service.js';
import type { AuthResponseDto, LoginDto, RegisterDto } from './dto.js';
import type { JwtPayload } from './jwt.strategy.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponseDto> {
    const existing = await this.users.findByEmailWithPassword(dto.email);
    if (existing) throw new ConflictException('An account already exists for this email');
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.users.create({ email: dto.email, name: dto.name.trim(), passwordHash });
    return this.issue(user);
  }

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.users.findByEmailWithPassword(dto.email);
    const ok = user && (await bcrypt.compare(dto.password, user.passwordHash));
    if (!ok) throw new UnauthorizedException('Invalid email or password');
    return this.issue(user);
  }

  private async issue(user: { id: string; email: string; name: string }): Promise<AuthResponseDto> {
    const payload: JwtPayload = { sub: user.id, email: user.email };
    return {
      accessToken: await this.jwt.signAsync(payload),
      user: { id: user.id, email: user.email, name: user.name },
    };
  }
}
