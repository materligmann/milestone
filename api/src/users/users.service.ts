import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities.js';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly users: Repository<User>) {}

  findById(id: string): Promise<User | null> {
    return this.users.findOne({ where: { id } });
  }

  /** Includes the password hash; only for authentication. */
  findByEmailWithPassword(email: string): Promise<User | null> {
    return this.users
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.email = :email', { email: email.toLowerCase() })
      .getOne();
  }

  async create(input: { email: string; name: string; passwordHash: string }): Promise<User> {
    const user = this.users.create({ ...input, email: input.email.toLowerCase() });
    const saved = await this.users.save(user);
    return { id: saved.id, email: saved.email, name: saved.name, createdAt: saved.createdAt } as User;
  }

  count(): Promise<number> {
    return this.users.count();
  }
}
