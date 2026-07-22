"use client";

import { MoreHorizontal } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ApiError } from "@/lib/api";

/** Shared row-level Edit/Delete menu for list-page tables. Edit is left to
 * the caller (usually flips the row into an already-existing add/edit
 * dialog, controlled open/onOpenChange); Delete shows a confirmation and
 * calls the soft-delete endpoint, toasting on success/failure. Drop this
 * into any list page's last column to get the same UX for free. */
export function RowActions({
  resourceLabel,
  onEdit,
  onDelete,
  deleteDescription,
}: {
  resourceLabel: string;
  onEdit: () => void;
  onDelete: () => Promise<unknown>;
  deleteDescription?: string;
}) {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  async function handleDelete() {
    setIsDeleting(true);
    try {
      await onDelete();
      toast.success(`${resourceLabel} deleted.`);
      setConfirmOpen(false);
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : `Failed to delete this ${resourceLabel.toLowerCase()}.`);
    } finally {
      setIsDeleting(false);
    }
  }

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            aria-label="Open actions"
            onClick={(event) => event.stopPropagation()}
          >
            <MoreHorizontal />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" onClick={(event) => event.stopPropagation()}>
          <DropdownMenuItem onSelect={() => onEdit()}>Edit</DropdownMenuItem>
          <DropdownMenuItem variant="destructive" onSelect={() => setConfirmOpen(true)}>
            Delete
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <AlertDialog open={confirmOpen} onOpenChange={(next) => !isDeleting && setConfirmOpen(next)}>
        <AlertDialogContent onClick={(event) => event.stopPropagation()}>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this {resourceLabel.toLowerCase()}?</AlertDialogTitle>
            <AlertDialogDescription>
              {deleteDescription ??
                "It will disappear from lists immediately. This is a soft delete - the record stays in the database and can be restored later if needed."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isDeleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={(event) => {
                event.preventDefault();
                handleDelete();
              }}
              disabled={isDeleting}
              className="bg-destructive text-white hover:bg-destructive/90"
            >
              {isDeleting ? "Deleting..." : "Delete"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
