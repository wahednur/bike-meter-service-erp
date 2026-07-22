"use client";

import { Check, ChevronsUpDown } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";

export interface ComboboxOption<T extends string | number = number> {
  value: T;
  label: string;
  description?: string;
}

interface ComboboxProps<T extends string | number = number> {
  options: ComboboxOption<T>[];
  value: T | null;
  onChange: (value: T | null) => void;
  placeholder?: string;
  disabled?: boolean;
  /** Shows a "— None —" row for optional fields (e.g. mileage correction
   * device, which only applies to some meter entries). */
  allowClear?: boolean;
  emptyMessage?: string;
  searchPlaceholder?: string;
}

export function Combobox<T extends string | number = number>({
  options,
  value,
  onChange,
  placeholder = "Select...",
  disabled = false,
  allowClear = false,
  emptyMessage = "No results found.",
  searchPlaceholder = "Search...",
}: ComboboxProps<T>) {
  const [open, setOpen] = useState(false);
  const selected = options.find((option) => option.value === value) ?? null;

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          role="combobox"
          aria-expanded={open}
          disabled={disabled}
          className="w-full justify-between font-normal"
        >
          <span className={cn("truncate", !selected && "text-muted-foreground")}>
            {selected ? selected.label : placeholder}
          </span>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-(--radix-popover-trigger-width) p-0" align="start">
        <Command>
          <CommandInput placeholder={searchPlaceholder} />
          <CommandList>
            <CommandEmpty>{emptyMessage}</CommandEmpty>
            <CommandGroup>
              {allowClear && (
                <CommandItem
                  value="__clear__"
                  onSelect={() => {
                    onChange(null);
                    setOpen(false);
                  }}
                >
                  <Check className={cn("mr-2 h-4 w-4", value === null ? "opacity-100" : "opacity-0")} />
                  <span className="text-muted-foreground">— None —</span>
                </CommandItem>
              )}
              {options.map((option) => (
                <CommandItem
                  key={option.value}
                  value={`${option.label} ${option.description ?? ""}`}
                  onSelect={() => {
                    onChange(option.value);
                    setOpen(false);
                  }}
                >
                  <Check className={cn("mr-2 h-4 w-4", value === option.value ? "opacity-100" : "opacity-0")} />
                  <span>{option.label}</span>
                  {option.description && (
                    <span className="ml-2 text-xs text-muted-foreground">{option.description}</span>
                  )}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
