import { NextResponse } from "next/server";

export async function DELETE() {
  return NextResponse.json(
    { message: "Esta acción solo está disponible en la aplicación administrativa." },
    { status: 403 },
  );
}
