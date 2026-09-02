import { NextResponse } from "next/server";

const backend = () => (process.env.BACKEND_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000").replace(/\/$/, "");

export async function GET(request: Request) {
  const authorization = request.headers.get("authorization");
  const response = await fetch(`${backend()}/cash-drawer/today`, {
    cache: "no-store",
    headers: authorization ? { authorization } : {},
  });
  return NextResponse.json(await response.json().catch(() => null), { status: response.status });
}
