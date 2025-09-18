import { usePage } from "@inertiajs/react";
import React from "react";

import { default as CollabsPage, CollabsPageProps } from "$app/components/server-components/CollabsPage";

function Collabs() {
  const { collabs_page_props } = usePage<{ collabs_page_props: CollabsPageProps }>().props;

  return <CollabsPage {...collabs_page_props} />;
}

export default Collabs;
