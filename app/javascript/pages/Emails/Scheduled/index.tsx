import { usePage } from "@inertiajs/react";
import React from "react";
import { cast } from "ts-safe-cast";

import { Pagination, ScheduledInstallment } from "$app/data/installments";

import { EmailsPageShell } from "$app/components/EmailsPage";
import { ScheduledTab } from "$app/components/EmailsPage/ScheduledTab";

type PageProps = {
  installments: ScheduledInstallment[];
  pagination: Pagination;
};

export default function EmailsScheduledPage() {
  const { installments, pagination } = cast<PageProps>(usePage().props);

  return (
    <EmailsPageShell selectedTab="scheduled" hasPosts={installments.length > 0}>
      <ScheduledTab defaultInstallments={installments} defaultPagination={pagination} />
    </EmailsPageShell>
  );
}

