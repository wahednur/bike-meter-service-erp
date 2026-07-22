"use client";

import { CalendarIcon, X } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";

function toDateKey(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function fromDateKey(value: string): Date {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day);
}

export function DatePickerButton({
  value,
  onChange,
  placeholder = "Pick a date",
}: {
  value: string | undefined;
  onChange: (value: string | undefined) => void;
  placeholder?: string;
}) {
  const [open, setOpen] = useState(false);
  const selected = value ? fromDateKey(value) : undefined;

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button type="button" variant="outline" className="justify-between font-normal">
          <span className={cn("flex items-center gap-2", !selected && "text-muted-foreground")}>
            <CalendarIcon className="h-4 w-4" />
            {selected ? selected.toLocaleDateString() : placeholder}
          </span>
          {selected && (
            <X
              className="h-4 w-4 text-muted-foreground hover:text-foreground"
              onClick={(event) => {
                event.stopPropagation();
                onChange(undefined);
              }}
            />
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto p-0" align="start">
        <Calendar
          mode="single"
          selected={selected}
          onSelect={(date) => {
            onChange(date ? toDateKey(date) : undefined);
            setOpen(false);
          }}
        />
      </PopoverContent>
    </Popover>
  );
}
