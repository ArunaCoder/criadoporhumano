import { getUser } from "@/services/userService";

export function validate(id: number): boolean {
  // Circularidade intencional para teste
  const user = getUser(id);
  return id > 0 && user !== null;
}

export function validateEmail(email: string): boolean {
  return email.includes("@");
}
