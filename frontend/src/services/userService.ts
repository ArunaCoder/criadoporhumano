import { validate } from "@/utils/validator";

export function getUser(id: number) {
  if (validate(id)) {
    return { id, name: "User" };
  }
  return null;
}

export function createUser(name: string) {
  return { id: Math.random(), name };
}
