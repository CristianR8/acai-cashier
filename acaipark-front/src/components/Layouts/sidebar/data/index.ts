import * as Icons from "../icons";
import type { ComponentType } from "react";

type NavigationSection = {
  label: string;
  items: Array<{
    title: string;
    url?: string;
    icon: ComponentType<any>;
    items?: Array<{ title: string; url: string }>;
  }>;
};

export const NAV_DATA: NavigationSection[] = [
  {
    label: "MENU PRINCIPAL",
    items: [
      {
        title: "Toma de pedidos",
        url: "/pos",
        icon: Icons.CiShop,
        items: [],
      },
    ],
  },
];
