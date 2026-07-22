"use client";

import { ChevronDown, ChevronRight } from "lucide-react";
import { useEffect, useState, type ChangeEvent, type ReactNode } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { importCustomersCsv, previewCustomerCsv } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { CustomerCsvImportResult, CustomerCsvPreview } from "@/lib/types";

type Step = "upload" | "map" | "confirm";

/** Best-effort auto-match: picks the first header whose normalized text
 * contains one of the keywords, so an obvious "Customer Name" or "Mobile"
 * column is pre-selected instead of forcing the user to pick it manually. */
function guessColumn(headers: string[], keywords: string[]): string {
  return (
    headers.find((header) => {
      const normalized = header.toLowerCase().replace(/[^a-z]/g, "");
      return keywords.some((keyword) => normalized.includes(keyword));
    }) ?? ""
  );
}

export function CustomerImportDialog({
  trigger,
  onImported,
}: {
  trigger: ReactNode;
  onImported: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState<Step>("upload");
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<CustomerCsvPreview | null>(null);
  const [nameColumn, setNameColumn] = useState("");
  const [phoneColumn, setPhoneColumn] = useState("");
  const [isUploading, setIsUploading] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [result, setResult] = useState<CustomerCsvImportResult | null>(null);
  const [showFailedRows, setShowFailedRows] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) return;
    setStep("upload");
    setFile(null);
    setPreview(null);
    setNameColumn("");
    setPhoneColumn("");
    setResult(null);
    setShowFailedRows(false);
    setError(null);
  }, [open]);

  async function handleFileSelected(event: ChangeEvent<HTMLInputElement>) {
    const selected = event.target.files?.[0];
    event.target.value = "";
    if (!selected) return;

    setError(null);
    setIsUploading(true);
    try {
      const previewData = await previewCustomerCsv(selected);
      setFile(selected);
      setPreview(previewData);
      setNameColumn(guessColumn(previewData.headers, ["name"]));
      setPhoneColumn(guessColumn(previewData.headers, ["phone", "mobile", "contact"]));
      setStep("map");
    } catch (err) {
      setError(reportError(err, "Failed to read that CSV file."));
    } finally {
      setIsUploading(false);
    }
  }

  async function handleImport() {
    if (!file || !nameColumn || !phoneColumn) return;
    setError(null);
    setIsImporting(true);
    try {
      const importResult = await importCustomersCsv(file, { name: nameColumn, phone: phoneColumn });
      setResult(importResult);
      toast.success(
        `Import finished: ${importResult.created_count} created, ${importResult.skipped_count} skipped, ${importResult.failed_count} failed.`,
      );
      onImported();
    } catch (err) {
      setError(reportError(err, "Failed to import customers."));
    } finally {
      setIsImporting(false);
    }
  }

  const isMappingValid = !!nameColumn && !!phoneColumn;

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>Import Customers from CSV</DialogTitle>
          <DialogDescription>
            {step === "upload" && "Upload a CSV file to preview its columns."}
            {step === "map" && "Confirm which CSV columns hold the customer name and phone number."}
            {step === "confirm" && (result ? "Import complete." : "Review your mapping, then start the import.")}
          </DialogDescription>
        </DialogHeader>

        {step === "upload" && (
          <div className="space-y-3">
            <Label htmlFor="customer-csv-file">CSV file</Label>
            <input
              id="customer-csv-file"
              type="file"
              accept=".csv,text/csv"
              onChange={handleFileSelected}
              disabled={isUploading}
              className="block w-full text-sm text-foreground file:mr-3 file:rounded-md file:border-0 file:bg-secondary file:px-3 file:py-1.5 file:text-sm file:font-medium file:text-secondary-foreground hover:file:bg-secondary/80"
            />
            {isUploading && <p className="text-sm text-muted-foreground">Reading file...</p>}
            {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          </div>
        )}

        {step === "map" && preview && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2">
                <Label>Which column is the Customer Name?</Label>
                <Select value={nameColumn} onValueChange={setNameColumn}>
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Select column" />
                  </SelectTrigger>
                  <SelectContent>
                    {preview.headers.map((header) => (
                      <SelectItem key={header} value={header}>
                        {header}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Which column is the Phone Number?</Label>
                <Select value={phoneColumn} onValueChange={setPhoneColumn}>
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Select column" />
                  </SelectTrigger>
                  <SelectContent>
                    {preview.headers.map((header) => (
                      <SelectItem key={header} value={header}>
                        {header}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div>
              <p className="mb-2 text-xs font-semibold text-muted-foreground uppercase">
                Preview (first {preview.rows.length} row{preview.rows.length === 1 ? "" : "s"})
              </p>
              <div className="max-h-56 overflow-auto rounded-lg border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      {preview.headers.map((header) => (
                        <TableHead key={header}>{header}</TableHead>
                      ))}
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {preview.rows.map((row, index) => (
                      <TableRow key={index}>
                        {preview.headers.map((header) => (
                          <TableCell key={header}>{row[header] ?? ""}</TableCell>
                        ))}
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </div>

            {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}

            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setStep("upload")}>
                Back
              </Button>
              <Button type="button" disabled={!isMappingValid} onClick={() => setStep("confirm")}>
                Continue
              </Button>
            </DialogFooter>
          </div>
        )}

        {step === "confirm" && !result && (
          <div className="space-y-4">
            <div className="rounded-lg border bg-muted/30 p-3 text-sm">
              <dl className="space-y-1">
                <div className="flex justify-between gap-4">
                  <dt className="text-muted-foreground">File</dt>
                  <dd className="font-medium">{file?.name}</dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-muted-foreground">Name column</dt>
                  <dd className="font-medium">{nameColumn}</dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-muted-foreground">Phone column</dt>
                  <dd className="font-medium">{phoneColumn}</dd>
                </div>
              </dl>
            </div>
            {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setStep("map")} disabled={isImporting}>
                Back
              </Button>
              <Button type="button" onClick={handleImport} disabled={isImporting}>
                {isImporting ? "Importing..." : "Import"}
              </Button>
            </DialogFooter>
          </div>
        )}

        {step === "confirm" && result && (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-3">
              <div className="rounded-lg border p-3 text-center">
                <p className="text-2xl font-semibold text-primary">{result.created_count}</p>
                <p className="text-xs text-muted-foreground">Created</p>
              </div>
              <div className="rounded-lg border p-3 text-center">
                <p className="text-2xl font-semibold">{result.skipped_count}</p>
                <p className="text-xs text-muted-foreground">Skipped (duplicates)</p>
              </div>
              <div className="rounded-lg border p-3 text-center">
                <p className="text-2xl font-semibold text-destructive">{result.failed_count}</p>
                <p className="text-xs text-muted-foreground">Failed</p>
              </div>
            </div>

            <p className="text-sm text-muted-foreground">Processed {result.total} row(s) total.</p>

            {result.skipped_count > 0 && (
              <div>
                <p className="mb-1 text-sm font-medium">Skipped duplicates</p>
                <div className="flex flex-wrap gap-1">
                  {result.skipped.map((skippedRow) => (
                    <Badge key={skippedRow.row} variant="secondary">
                      Row {skippedRow.row}: {skippedRow.phone}
                    </Badge>
                  ))}
                </div>
              </div>
            )}

            {result.failed_count > 0 && (
              <div>
                <button
                  type="button"
                  onClick={() => setShowFailedRows((prev) => !prev)}
                  className="flex items-center gap-1 text-sm font-medium hover:underline"
                >
                  {showFailedRows ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                  {showFailedRows ? "Hide" : "Show"} failed rows ({result.failed_count})
                </button>
                {showFailedRows && (
                  <div className="mt-2 max-h-40 overflow-auto rounded-lg border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="w-20">Row</TableHead>
                          <TableHead>Reason</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {result.failed.map((failedRow) => (
                          <TableRow key={failedRow.row}>
                            <TableCell>
                              <Badge variant="outline">Row {failedRow.row}</Badge>
                            </TableCell>
                            <TableCell className="whitespace-normal">{failedRow.reason}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                )}
              </div>
            )}

            <DialogFooter>
              <Button type="button" onClick={() => setOpen(false)}>
                Done
              </Button>
            </DialogFooter>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
