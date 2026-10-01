import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Produces a minimal self-contained Node server for the production image.
  output: "standalone",
};

export default nextConfig;
