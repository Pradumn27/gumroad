import { Link, usePage } from "@inertiajs/react";
import cx from "classnames";
import React from "react";

import { previewInstallment, SavedInstallment } from "$app/data/installments";
import { assertDefined } from "$app/utils/assert";
import { formatStatNumber } from "$app/utils/formatStatNumber";
import { asyncVoid } from "$app/utils/promise";
import { assertResponseError } from "$app/utils/request";

import { Button } from "$app/components/Button";
import { Icon } from "$app/components/Icons";
import { Popover } from "$app/components/Popover";
import { showAlert } from "$app/components/server-components/Alert";
import { PageHeader } from "$app/components/ui/PageHeader";
import Placeholder from "$app/components/ui/Placeholder";
import { Tabs, Tab } from "$app/components/ui/Tabs";
import { WithTooltip } from "$app/components/WithTooltip";

const EMAIL_TABS = ["published", "scheduled", "drafts"] as const;
const TABS = [...EMAIL_TABS, "subscribers"] as const;

export type EmailTab = (typeof EMAIL_TABS)[number];

export const emailTabPath = (tab: EmailTab) => `/emails/${tab}`;
export const newEmailPath = "/emails/new";
export const editEmailPath = (id: string) => `/emails/${id}/edit`;

const SearchContext = React.createContext<[string, (value: string) => void] | null>(null);
export const useSearchContext = () => assertDefined(React.useContext(SearchContext));

export const EmailsPageShell = ({
  selectedTab,
  hasPosts,
  children,
}: {
  selectedTab: EmailTab;
  hasPosts?: boolean;
  children: React.ReactNode;
}) => {
  const queryState = React.useState("");
  return (
    <SearchContext.Provider value={queryState}>
      <Layout selectedTab={selectedTab} hasPosts={hasPosts}>
        {children}
      </Layout>
    </SearchContext.Provider>
  );
};

export const Layout = ({
  selectedTab,
  children,
  hasPosts,
}: {
  selectedTab: EmailTab;
  children: React.ReactNode;
  hasPosts?: boolean;
}) => {
  const searchInputRef = React.useRef<HTMLInputElement>(null);
  const [isSearchPopoverOpen, setIsSearchPopoverOpen] = React.useState(false);
  const [query, setQuery] = useSearchContext();
  React.useEffect(() => {
    if (isSearchPopoverOpen) searchInputRef.current?.focus();
  }, [isSearchPopoverOpen]);

  return (
    <div>
      <PageHeader
        title="Emails"
        actions={
          <>
            {hasPosts ? (
              <Popover
                open={isSearchPopoverOpen}
                onToggle={setIsSearchPopoverOpen}
                aria-label="Toggle Search"
                trigger={
                  <WithTooltip tip="Search" position="bottom">
                    <div className="button">
                      <Icon name="solid-search" />
                    </div>
                  </WithTooltip>
                }
              >
                <div className="input">
                  <Icon name="solid-search" />
                  <input
                    ref={searchInputRef}
                    type="text"
                    placeholder="Search emails"
                    value={query}
                    onChange={(evt) => setQuery(evt.target.value)}
                  />
                </div>
              </Popover>
            ) : null}
            <NewEmailButton />
          </>
        }
      >
        <Tabs>
          {TABS.map((tab) =>
            tab === "subscribers" ? (
              <Tab href={Routes.followers_path()} isSelected={false} key={tab}>
                Subscribers
              </Tab>
            ) : (
              <Tab isSelected={selectedTab === tab} key={tab} asChild>
                <Link href={emailTabPath(tab)}>
                  {tab === "published" ? "Published" : tab === "scheduled" ? "Scheduled" : "Drafts"}
                </Link>
              </Tab>
            ),
          )}
        </Tabs>
      </PageHeader>
      {children}
    </div>
  );
};

export const appendFromParam = (path: string, from: string) => {
  const params = new URLSearchParams();
  if (path.includes("?")) {
    const [base, search] = path.split("?");
    const searchParams = new URLSearchParams(search);
    searchParams.forEach((value, key) => params.append(key, value));
    path = base;
  }
  if (from) params.set("from", from);
  const query = params.toString();
  return query ? `${path}?${query}` : path;
};

const useCurrentPathname = () => {
  const { url } = usePage();
  return React.useMemo(() => url.split("?")[0], [url]);
};

export const NewEmailButton = ({ copyFrom }: { copyFrom?: string }) => {
  const pathname = useCurrentPathname();
  const href = React.useMemo(() => {
    const params = new URLSearchParams();
    if (copyFrom) params.set("copy_from", copyFrom);
    if (pathname) params.set("from", pathname);
    const query = params.toString();
    return query ? `${newEmailPath}?${query}` : newEmailPath;
  }, [copyFrom, pathname]);

  return (
    <Link className={cx("button", { accent: !copyFrom })} href={href}>
      {copyFrom ? "Duplicate" : "New email"}
    </Link>
  );
};

export const EditEmailButton = ({ id }: { id: string }) => {
  const pathname = useCurrentPathname();
  const href = React.useMemo(() => appendFromParam(editEmailPath(id), pathname), [id, pathname]);
  return (
    <Link className="button" href={href}>
      Edit
    </Link>
  );
};

export const ViewEmailButton = (props: { installment: SavedInstallment }) => {
  const [sendingPreviewEmail, setSendingPreviewEmail] = React.useState(false);

  return (
    <Button
      disabled={sendingPreviewEmail}
      onClick={asyncVoid(async () => {
        setSendingPreviewEmail(true);
        try {
          await previewInstallment(props.installment.external_id);
          showAlert("A preview has been sent to your email.", "success");
        } catch (error) {
          assertResponseError(error);
          showAlert(error.message, "error");
        } finally {
          setSendingPreviewEmail(false);
        }
      })}
    >
      <Icon name="envelope-fill"></Icon>
      {sendingPreviewEmail ? "Sending..." : "View email"}
    </Button>
  );
};

export const EmptyStatePlaceholder = ({
  title,
  description,
  placeholderImage,
}: {
  title: string;
  description: string;
  placeholderImage: string;
}) => (
  <Placeholder>
    <figure>
      <img src={placeholderImage} />
    </figure>
    <h2>{title}</h2>
    <p>{description}</p>
    <NewEmailButton />
    <p>
      <a href="/help/article/169-how-to-send-an-update" target="_blank" rel="noreferrer">
        Learn more about emails
      </a>
    </p>
  </Placeholder>
);

export type AudienceCounts = Map<string, number | "loading" | "failed">;
export const audienceCountValue = (audienceCounts: AudienceCounts, installmentId: string) => {
  const count = audienceCounts.get(installmentId);
  return count === undefined || count === "loading"
    ? null
    : count === "failed"
      ? "--"
      : formatStatNumber({ value: count });
};
