import { cn } from "@/lib/utils";
import type { SVGProps } from "react";

export const PowerPelletIcon = (props: SVGProps<SVGSVGElement>) => (
  <div className={cn("w-full h-full rounded-full bg-accent", props.className)} />
);
