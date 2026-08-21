"use client";

import { useState } from "react";

type TouchKeyboardProps = {
  value: string;
  onChange: (value: string) => void;
  onClose: () => void;
  mode?: "text" | "email" | "password";
};

const LETTER_ROWS = ["qwertyuiop", "asdfghjkl", "zxcvbnm"];
const SYMBOL_ROWS = ["1234567890", "-/:;()$&@\"", ".,?!'_"];

export default function TouchKeyboard({
  value,
  onChange,
  onClose,
  mode = "text",
}: TouchKeyboardProps) {
  const [uppercase, setUppercase] = useState(false);
  const [symbols, setSymbols] = useState(false);
  const rows = symbols ? SYMBOL_ROWS : LETTER_ROWS;

  const add = (key: string) => {
    onChange(value + (uppercase && !symbols ? key.toUpperCase() : key));
    if (uppercase && !symbols) setUppercase(false);
  };

  return (
    <div
      className="fixed inset-x-0 bottom-1 z-[100] mx-auto w-[min(96vw,480px)] rounded-lg border border-stroke bg-white/98 p-1 shadow-2xl backdrop-blur dark:border-dark-3 dark:bg-dark/98"
      role="dialog"
      aria-label="Teclado táctil"
    >
      {rows.map((row, index) => (
        <div key={row} className="mb-px flex justify-center gap-px last:mb-0">
          {index === 2 && !symbols && (
            <KeyButton onClick={() => setUppercase((current) => !current)} active={uppercase}>
              ⇧
            </KeyButton>
          )}
          {row.split("").map((key) => (
            <KeyButton key={key} onClick={() => add(key)}>
              {uppercase && !symbols ? key.toUpperCase() : key}
            </KeyButton>
          ))}
          {index === 2 && (
            <KeyButton onClick={() => onChange(value.slice(0, -1))} className="px-2">
              ←
            </KeyButton>
          )}
        </div>
      ))}

      <div className="mt-px flex justify-center gap-px">
        <KeyButton onClick={() => setSymbols((current) => !current)} className="px-2 text-[10px]">
          {symbols ? "ABC" : "123"}
        </KeyButton>
        {mode === "email" && <KeyButton onClick={() => add("@")}>@</KeyButton>}
        {mode === "email" && <KeyButton onClick={() => onChange(value + ".com")} className="px-2 text-[10px]">.com</KeyButton>}
        <KeyButton onClick={() => add(" ")} className="min-w-24 flex-1 text-[10px]">espacio</KeyButton>
        <KeyButton onClick={onClose} className="px-2 text-[10px]">Listo</KeyButton>
      </div>
    </div>
  );
}

function KeyButton({
  children,
  onClick,
  className = "",
  active = false,
}: {
  children: React.ReactNode;
  onClick: () => void;
  className?: string;
  active?: boolean;
}) {
  return (
    <button
      type="button"
      onMouseDown={(event) => event.preventDefault()}
      onClick={onClick}
      className={`flex h-7 min-w-7 items-center justify-center rounded bg-gray-1 px-1.5 text-xs font-medium text-dark shadow-sm transition active:scale-95 dark:bg-dark-2 dark:text-white ${active ? "bg-primary text-white dark:bg-primary" : "hover:bg-gray-2 dark:hover:bg-dark-3"} ${className}`}
    >
      {children}
    </button>
  );
}
