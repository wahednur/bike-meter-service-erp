import { useMemo, useState } from "react";

/** The customers/suppliers list endpoints return a plain array with no
 * server-side search/pagination support, so this filters and pages client-side. */
export function usePaginatedList<T>(items: T[], matches: (item: T, query: string) => boolean, pageSize = 10) {
  const [search, setSearchRaw] = useState("");
  const [page, setPage] = useState(1);

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return items;
    return items.filter((item) => matches(item, query));
  }, [items, search, matches]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const currentPage = Math.min(page, totalPages);
  const pageItems = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  function setSearch(value: string) {
    setSearchRaw(value);
    setPage(1);
  }

  return {
    search,
    setSearch,
    page: currentPage,
    setPage,
    totalPages,
    pageItems,
    totalCount: filtered.length,
  };
}
