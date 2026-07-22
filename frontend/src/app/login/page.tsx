"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Field, FieldError, FieldGroup, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/lib/auth-context";
import { reportError } from "@/lib/errors";
import { useShopProfile } from "@/lib/shop-profile-context";

const loginSchema = z.object({
  identifier: z.string().min(1, "Email or phone is required"),
  password: z.string().min(1, "Password is required"),
});

type LoginFormValues = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const { login, user, isLoading } = useAuth();
  const { shopProfile, refresh: refreshShopProfile } = useShopProfile();
  const router = useRouter();
  const [formError, setFormError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { identifier: "", password: "" },
  });

  useEffect(() => {
    if (!isLoading && user) {
      router.replace("/dashboard");
    }
  }, [isLoading, user, router]);

  async function onSubmit(values: LoginFormValues) {
    setFormError(null);
    try {
      await login(values.identifier, values.password);
      refreshShopProfile();
      router.replace("/dashboard");
    } catch (err) {
      setFormError(reportError(err, "Something went wrong. Please try again."));
    }
  }

  return (
    <div className="flex flex-1 items-center justify-center px-4">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>{shopProfile.shop_name}</CardTitle>
          <CardDescription>Sign in with your email/phone and password.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)}>
            <FieldGroup>
              <Field data-invalid={!!errors.identifier}>
                <FieldLabel htmlFor="identifier">Email or phone</FieldLabel>
                <Input id="identifier" autoComplete="username" {...register("identifier")} />
                <FieldError errors={[errors.identifier]} />
              </Field>
              <Field data-invalid={!!errors.password}>
                <FieldLabel htmlFor="password">Password</FieldLabel>
                <Input id="password" type="password" autoComplete="current-password" {...register("password")} />
                <FieldError errors={[errors.password]} />
              </Field>
              {formError && (
                <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{formError}</p>
              )}
              <Button type="submit" disabled={isSubmitting} className="w-full">
                {isSubmitting ? "Signing in..." : "Sign in"}
              </Button>
            </FieldGroup>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
