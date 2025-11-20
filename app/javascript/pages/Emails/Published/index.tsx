import { usePage } from "@inertiajs/react";
import React from "react";
import { cast } from "ts-safe-cast";

import { Pagination, PublishedInstallment } from "$app/data/installments";

import { EmailsPageShell } from "$app/components/EmailsPage";
import { PublishedTab } from "$app/components/EmailsPage/PublishedTab";

type PageProps = {
  installments: PublishedInstallment[];
  pagination: Pagination;
};

export default function EmailsPublishedPage() {
  const { installments, pagination } = cast<PageProps>(usePage().props);

  return (
    <EmailsPageShell selectedTab="published" hasPosts={installments.length > 0}>
      <PublishedTab defaultInstallments={installments} defaultPagination={pagination} />
    </EmailsPageShell>
  );
}

