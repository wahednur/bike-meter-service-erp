"use client";

import { Check, ChevronsUpDown, Plus, X } from "lucide-react";
import { useState, type KeyboardEvent } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import { Input } from "@/components/ui/input";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";

interface MultiSelectProps {
  /** Suggested options - not a restriction when `allowCustom` is set. */
  options: string[];
  value: string[];
  onChange: (value: string[]) => void;
  placeholder?: string;
  disabled?: boolean;
  /** Shows a free-text "add custom" row so the user can add a tag that
   * isn't one of `options`. Any already-selected custom tags are folded
   * into the checkbox list too, so they can be toggled off like any other. */
  allowCustom?: boolean;
  customPlaceholder?: string;
}

/** shadcn-pattern multi-select: a Popover + Command list of checkboxes,
 * selections shown as removable badges on the trigger itself. Reused for
 * InvoiceMeterEntry.condition_note (a mix of preset + free-text tags). */
export function MultiSelect({
  options,
  value,
  onChange,
  placeholder = "Select...",
  disabled = false,
  allowCustom = false,
  customPlaceholder = "Add a custom condition...",
}: MultiSelectProps) {
  const [open, setOpen] = useState(false);
  const [customInput, setCustomInput] = useState("");

  function toggle(option: string) {
    onChange(value.includes(option) ? value.filter((tag) => tag !== option) : [...value, option]);
  }

  function remove(option: string) {
    onChange(value.filter((tag) => tag !== option));
  }

  function addCustom() {
    const trimmed = customInput.trim();
    setCustomInput("");
    if (!trimmed || value.includes(trimmed)) return;
    onChange([...value, trimmed]);
  }

  function handleCustomKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key !== "Enter") return;
    event.preventDefault();
    event.stopPropagation();
    addCustom();
  }

  // Already-selected tags that aren't one of the presets - shown in the
  // checkbox list too (checked), so they can be unchecked the same way.
  const customSelected = value.filter((tag) => !options.includes(tag));
  const allOptions = [...options, ...customSelected];

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          role="combobox"
          aria-expanded={open}
          disabled={disabled}
          className="h-auto min-h-9 w-full justify-between font-normal"
        >
          <span className="flex flex-1 flex-wrap items-center gap-1 text-left">
            {value.length === 0 ? (
              <span className="text-muted-foreground">{placeholder}</span>
            ) : (
              value.map((tag) => (
                <Badge key={tag} variant="secondary" className="gap-1 py-0.5">
                  {tag}
                  <span
                    role="button"
                    tabIndex={-1}
                    className="rounded-full hover:bg-muted-foreground/20"
                    onClick={(event) => {
                      event.stopPropagation();
                      remove(tag);
                    }}
                  >
                    <X className="h-3 w-3" />
                  </span>
                </Badge>
              ))
            )}
          </span>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 self-start opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-(--radix-popover-trigger-width) p-0" align="start">
        <Command>
          <CommandInput placeholder="Search conditions..." />
          <CommandList>
            <CommandEmpty>No matching condition.</CommandEmpty>
            <CommandGroup>
              {allOptions.map((option) => {
                const checked = value.includes(option);
                return (
                  <CommandItem key={option} value={option} onSelect={() => toggle(option)}>
                    <span
                      className={cn(
                        "flex h-4 w-4 shrink-0 items-center justify-center rounded-sm border",
                        checked ? "border-primary bg-primary text-primary-foreground" : "border-input",
                      )}
                    >
                      {checked && <Check className="h-3 w-3" />}
                    </span>
                    <span>{option}</span>
                  </CommandItem>
                );
              })}
            </CommandGroup>
            {allowCustom && (
              <>
                <CommandSeparator />
                <CommandGroup heading="Custom">
                  <div className="flex items-center gap-1 px-2 py-1.5">
                    <Input
                      value={customInput}
                      onChange={(event) => setCustomInput(event.target.value)}
                      onKeyDown={handleCustomKeyDown}
                      placeholder={customPlaceholder}
                      className="h-7"
                    />
                    <Button
                      type="button"
                      size="icon"
                      variant="ghost"
                      className="h-7 w-7 shrink-0"
                      disabled={!customInput.trim()}
                      onClick={addCustom}
                    >
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                </CommandGroup>
              </>
            )}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
