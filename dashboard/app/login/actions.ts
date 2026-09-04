"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

/// Supabase reports auth failures in English; a Berlin teacher must never see
/// that. Map the known cases to German and fall back to a neutral message.
function germanLoginError(error: { code?: string; message: string }): string {
  const code = error.code ?? "";
  const msg = error.message ?? "";
  if (code === "invalid_credentials" || msg.includes("Invalid login credentials")) {
    return "E-Mail-Adresse oder Passwort ist falsch.";
  }
  if (code === "email_not_confirmed" || msg.includes("Email not confirmed")) {
    return "Bitte bestätige zuerst deine E-Mail-Adresse.";
  }
  return "Anmeldung fehlgeschlagen. Bitte versuche es später noch einmal.";
}

export async function login(formData: FormData) {
  const supabase = await createClient();
  const email = formData.get("email") as string;
  const password = formData.get("password") as string;

  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    redirect("/login?error=" + encodeURIComponent(germanLoginError(error)));
  }
  revalidatePath("/", "layout");
  redirect("/dashboard");
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  revalidatePath("/", "layout");
  redirect("/login");
}
