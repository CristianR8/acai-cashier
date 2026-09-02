import { NextResponse } from "next/server";

const backend = () => (process.env.BACKEND_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000").replace(/\/$/, "");

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const authorization = request.headers.get("authorization");
  const response = await fetch(`${backend()}/cash-drawer/opening`, {
    method: "POST",
    headers: { "content-type": "application/json", ...(authorization ? { authorization } : {}) },
    body: JSON.stringify(body),
  });
  return NextResponse.json(await response.json().catch(() => null), { status: response.status });
}
