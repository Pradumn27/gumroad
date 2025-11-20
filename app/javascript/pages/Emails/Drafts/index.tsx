import { usePage } from "@inertiajs/react";
import React from "react";
import { cast } from "ts-safe-cast";

import { DraftInstallment, Pagination } from "$app/data/installments";

import { EmailsPageShell } from "$app/components/EmailsPage";
import { DraftsTab } from "$app/components/EmailsPage/DraftsTab";

type PageProps = {
  installments: DraftInstallment[];
  pagination: Pagination;
};

export default function EmailsDraftsPage() {
  const { installments, pagination } = cast<PageProps>(usePage().props);

  return (
    <EmailsPageShell selectedTab="drafts" hasPosts={installments.length > 0}>
      <DraftsTab defaultInstallments={installments} defaultPagination={pagination} />
    </EmailsPageShell>
  );
}

