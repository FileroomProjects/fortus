# Fortus

A Ruby on Rails integration platform that synchronizes data between HubSpot CRM and NetSuite ERP systems. Provides bidirectional data flow for deals, contacts, companies, quotes, opportunities, and sales orders.

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Domain Models](#domain-models)
- [Key Functions](#key-functions)
- [API Endpoints](#api-endpoints)
- [Logging Standards](#logging-standards)
- [Field Mappings](#field-mappings)
- [References](#references)

## Overview

Fortus serves as middleware enabling real-time synchronization between HubSpot and NetSuite. The application handles OAuth2 authentication, token management, bidirectional object synchronization, webhook processing, and data transformation between platform schemas.

**Synchronization Flow:**
- HubSpot → NetSuite: Deals, Contacts, Companies, Quotes
- NetSuite → HubSpot: Sales Orders, Estimates, Opportunities

## Repository Structure

### Directory Organization

```
app/
├── controllers/          # HTTP request handlers
│   ├── hubspots_controller.rb    # HubSpot webhook endpoints
│   └── netsuite_controller.rb    # NetSuite webhook endpoints
├── models/
│   ├── concerns/        # Shared modules (HttpsRequest, IntegrationCommon)
│   ├── hubspot/         # HubSpot domain models
│   │   ├── base.rb      # Base class for HubSpot models
│   │   ├── client.rb    # HubSpot API client
│   │   ├── deal.rb      # Deal synchronization logic
│   │   ├── contact.rb   # Contact operations
│   │   ├── company.rb   # Company operations
│   │   ├── quote_deal.rb # Quote deal operations
│   │   └── deal/        # Deal helper modules
│   └── netsuite/        # NetSuite domain models
│       ├── base.rb      # Base class with OAuth2 token management
│       ├── client.rb    # NetSuite API client
│       ├── quote.rb     # Quote/Estimate operations
│       ├── opportunity.rb # Opportunity operations
│       ├── sales_order.rb # Sales order operations
│       └── hubspot/     # NetSuite-to-HubSpot helper modules
├── views/               # ERB templates
└── jobs/                # Background jobs

db/
├── schema.rb            # Database schema
└── migrate/             # Database migrations
```

### Naming Conventions

- **Controllers**: Plural nouns (`HubspotsController`, `NetsuiteController`)
- **Models**: Namespaced modules (`Hubspot::Deal`, `Netsuite::Quote`)
- **Helpers**: Organized by domain (`Hubspot::Deal::NetsuiteOpportunityHelper`)
- **Routes**: RESTful conventions with custom actions

## Domain Models

### Core Models

#### Token

Manages OAuth2 access tokens for external API integrations.

**Attributes:**
- `access_token` (text): Encrypted access token
- `refresh_token` (text): Token for refreshing access
- `expires_at` (datetime): Token expiration timestamp
- `expires_in` (string): Expiration duration in seconds
- `provider` (string): Integration provider name (e.g., "netsuite")

**Key Methods:**
- `expired?`: Checks if token has expired
- `expires_in_seconds`: Calculates remaining validity
- `self.netsuite_token`: Retrieves NetSuite token
- `self.update_netsuite_token`: Updates token with new credentials

### HubSpot Models

#### Hubspot::Base

Base class for all HubSpot domain models. Provides common functionality for API interactions.

**Attributes:**
- `args`: Parameter hash with indifferent access
- `properties`: Extracted properties hash
- `deal_id`: Associated deal identifier

**Included Modules:**
- `IntegrationCommon`: Shared integration utilities

#### Hubspot::Client

HTTP client for HubSpot API interactions. Base URL: `https://api.hubapi.com`

**Key Methods:**
- `fetch_deal(deal_id)`: Retrieves deal by ID
- `create_objects(object_type)`: Creates new objects
- `update_deal(attributes)`: Updates deal properties
- `search_object(object_type)`: Searches objects with filters
- `create_association(from_type, to_type)`: Creates object associations

#### Hubspot::Deal

Primary model for HubSpot deal synchronization.

**Key Attributes:**
- `deal_id`: HubSpot deal identifier
- `properties`: Deal properties hash
- `netsuite_opportunity_id`: Linked NetSuite opportunity ID

**Key Methods:**
- `sync_contact_customer_with_netsuite`: Main synchronization method
- `sync_quotes_and_opportunity_with_netsuite`: Syncs quotes and opportunities
- `associated_company`: Retrieves associated company
- `associated_contact`: Retrieves associated contact
- `update(attributes)`: Updates deal in HubSpot
- `fetch_prop_field(field_name)`: Extracts property field value

**Helper Modules:**
- `NetsuiteOpportunityHelper`: Opportunity synchronization logic
- `NetsuiteContactHelper`: Contact synchronization logic
- `NetsuiteCompanyHelper`: Company synchronization logic
- `NetsuiteQuoteHelper`: Quote synchronization logic
- `HubspotQuoteDealHelper`: Quote deal creation logic

#### Hubspot::Contact

Handles HubSpot contact operations.

**Key Methods:**
- `find_by_deal_id(deal_id)`: Finds contact associated with deal
- `find_by_id(contact_id)`: Retrieves contact by ID

#### Hubspot::Company

Handles HubSpot company operations.

**Key Methods:**
- `fetch_by_deal_id(deal_id)`: Retrieves company associated with deal
- `find_by_id(company_id)`: Retrieves company by ID

#### Hubspot::QuoteDeal

Handles HubSpot quote deal operations.

**Key Methods:**
- `create(payload)`: Creates new quote deal
- `update(payload)`: Updates existing quote deal

### NetSuite Models

#### Netsuite::Base

Base class for NetSuite domain models. Handles OAuth2 token management.

**Key Class Methods:**
- `exchange_code_for_token(code)`: Exchanges authorization code for access token
- `get_access_token`: Retrieves valid access token (auto-refreshes if expired)

**Token Management:**
Automatically refreshes tokens when expired or within 5 minutes of expiration.

#### Netsuite::Client

HTTP client for NetSuite SuiteTalk API interactions.

**Base URLs:**
- REST API: `https://{account}.suitetalk.api.netsuite.com/services/rest/record/v1`
- SuiteQL: `https://{account}.suitetalk.api.netsuite.com/services/rest/query/v1/suiteql`

**Key Methods:**
- `fetch_object(name, id)`: Retrieves object by type and ID
- `create_object(object_name)`: Creates new NetSuite object
- `search_contact_by_id`: Searches contacts by ID
- `search_customer_by_properties`: Searches customers with SuiteQL
- `fetch_estimate_items(estimate_id)`: Retrieves quote line items

#### Netsuite::Quote

Handles quote/estimate synchronization with HubSpot.

**Key Methods:**
- `self.create(args)`: Creates new quote in NetSuite
- `self.show(quote_id)`: Retrieves quote by ID
- `self.fetch_items(quote_id)`: Retrieves quote line items
- `sync_quote_estimate_with_quote_deal`: Synchronizes quote to HubSpot

#### Netsuite::Opportunity

Handles NetSuite opportunity synchronization with HubSpot deals.

**Key Methods:**
- `self.create(args)`: Creates new opportunity in NetSuite
- `self.show(opportunity_id)`: Retrieves opportunity by ID
- `sync_opportunity_with_deal`: Synchronizes opportunity to HubSpot deal

#### Netsuite::SalesOrder

Handles NetSuite sales order synchronization with HubSpot.

**Key Methods:**
- `sync_sales_order_with_hubspot`: Main synchronization method
- `find_associated_hubspot_records`: Finds related HubSpot objects

### Concerns

#### IntegrationCommon

Shared utilities for integration logic.

**Key Methods:**
- `build_search_payload(filters)`: Constructs HubSpot search payload
- `build_search_filter(property, operator, value)`: Builds filter objects
- `payload_to_associate(from_id, to_id, type)`: Creates association payload
- `association(target_id, type_id)`: Builds association structure
- `object_present_with_id?(object)`: Validates object presence

#### HttpsRequest

HTTP request methods using HTTParty.

**Key Methods:**
- `post_request(url, body, headers)`: POST request
- `patch_request(url, body, headers)`: PATCH request
- `get_request(url, headers)`: GET request
- `delete_request(url, headers)`: DELETE request
- `search_query(url, query, headers)`: GET with query parameters

## Key Functions

### Synchronization Flows

#### HubSpot to NetSuite

1. **Deal Synchronization** (`Hubspot::Deal#sync_contact_customer_with_netsuite`)
   - Syncs associated company to NetSuite customer
   - Syncs associated contact to NetSuite contact
   - Creates or updates NetSuite opportunity
   - Creates NetSuite quote if opportunity exists
   - Creates HubSpot child quote deal

2. **Quote Creation** (`HubspotsController#create_ns_quote`)
   - Prepares payload from HubSpot deal
   - Creates NetSuite quote/estimate
   - Creates HubSpot quote deal
   - Associates quote deal with parent deal

#### NetSuite to HubSpot

1. **Sales Order Sync** (`Netsuite::SalesOrder#sync_sales_order_with_hubspot`)
   - Finds or creates HubSpot order
   - Updates associated deal
   - Syncs line items

2. **Estimate Sync** (`Netsuite::Quote#sync_quote_estimate_with_quote_deal`)
   - Updates HubSpot quote deal
   - Syncs line items
   - Updates company and contact information

3. **Opportunity Sync** (`Netsuite::Opportunity#sync_opportunity_with_deal`)
   - Updates associated HubSpot deal

### Authentication

- **OAuth2 Flow**: NetSuite authentication via callback endpoint
- **Token Management**: Automatic token refresh handled by `Netsuite::Base`
- **Token Storage**: Tokens stored in `tokens` table with expiration tracking

## API Endpoints

### HubSpot Endpoints

- `POST /hubspot/callback`: Webhook endpoint for HubSpot events
- `POST /hubspot/create_contact_customer`: Synchronizes HubSpot deal contact and customer to NetSuite
- `GET /hubspot/create_ns_quote`: Creates NetSuite quote from HubSpot deal and creates child quote deal
- `GET /hubspot/create_duplicate_ns_quote`: Creates duplicate NetSuite quote from parent deal

### NetSuite Endpoints

- `GET /netsuite/callback`: OAuth2 callback endpoint for NetSuite authentication
- `POST /netsuite/sync_order`: Synchronizes NetSuite sales order to HubSpot
- `POST /netsuite/sync_estimate`: Synchronizes NetSuite estimate/quote to HubSpot quote deal
- `POST /netsuite/sync_deal`: Synchronizes NetSuite opportunity to HubSpot deal

### Health Check

- `GET /up`: Application health check endpoint

## Logging Standards

All application logs follow a structured hierarchical format for monitoring and filtering in Papertrail.

### Log Format

```
[LEVEL] [COMPONENT] [ACTION] [CONTEXT] Message
```

### Component Hierarchy

**Primary:** `INTEGRATION`, `API`, `AUTH`, `SYNC`, `MODEL`, `CONTROLLER`

**Secondary (Provider):** `INTEGRATION.HUBSPOT`, `INTEGRATION.NETSUITE`, `API.HUBSPOT`, `API.NETSUITE`, `SYNC.HUBSPOT_TO_NETSUITE`, `SYNC.NETSUITE_TO_HUBSPOT`

**Tertiary (Object):** `SYNC.HUBSPOT_TO_NETSUITE.DEAL`, `SYNC.HUBSPOT_TO_NETSUITE.CONTACT`, `SYNC.HUBSPOT_TO_NETSUITE.COMPANY`, `SYNC.HUBSPOT_TO_NETSUITE.QUOTE`, `SYNC.NETSUITE_TO_HUBSPOT.ORDER`, `SYNC.NETSUITE_TO_HUBSPOT.ESTIMATE`, `SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY`

### Action Types

`START`, `COMPLETE`, `FAIL`, `RETRY`, `SKIP`, `CREATE`, `UPDATE`, `FETCH`, `DELETE`, `SEARCH`, `VALIDATE`, `TRANSFORM`

### Log Levels

`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`

### Log Examples

**Integration Start:**
```
[INFO] [INTEGRATION.HUBSPOT_TO_NETSUITE.DEAL] [START] [deal_id:12345] Synchronization initiated
```

**API Call:**
```
[INFO] [API.HUBSPOT] [FETCH] [deal_id:12345] Fetching deal from HubSpot API
```

**Success:**
```
[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id:12345, netsuite_opportunity_id:67890] Deal synchronized successfully
```

**Error:**
```
[ERROR] [API.NETSUITE] [CREATE] [deal_id:12345] Failed to create NetSuite opportunity: Invalid customer ID
```

**Retry:**
```
[WARN] [SYNC.HUBSPOT_TO_NETSUITE.CONTACT] [RETRY] [contact_id:54321, attempt:2] Retrying contact synchronization
```

**Token Operations:**
```
[INFO] [AUTH.NETSUITE] [FETCH] [provider:netsuite] Retrieving access token
[WARN] [AUTH.NETSUITE] [RETRY] [provider:netsuite] Token expired, refreshing access token
[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] Token refresh failed: Invalid refresh token
```

### Search Patterns for Papertrail

- All HubSpot operations: `INTEGRATION.HUBSPOT`
- All synchronization errors: `SYNC ERROR`
- Specific deal synchronization: `SYNC.HUBSPOT_TO_NETSUITE.DEAL deal_id:12345`
- All token refresh operations: `AUTH.NETSUITE RETRY`
- Failed API calls: `API FAIL`

For detailed logging standards and implementation guidelines, see `LOGGING_STANDARDS.md`.

## Field Mappings

Field mappings between HubSpot and NetSuite objects for synchronization operations.

### Deal ↔ Opportunity

**HubSpot → NetSuite (Deal to Opportunity)**

| HubSpot Field | NetSuite Field | Notes |
|---------------|----------------|-------|
| `dealname` | `title` | Deal name mapped to opportunity title |
| `createdate` | `tranDate` | Timestamp converted from milliseconds to date format |
| `closedate` | `expectedCloseDate` | Timestamp converted from milliseconds to date format |
| `hs_deal_stage_probability` | `probability` | Probability multiplied by 100 (NetSuite requires 1-100) |
| `hs_projected_amount` | `projectedTotal` | Projected deal amount |
| `hs_projected_amount` | `total` | Total opportunity amount |
| `netsuite_company_id` (from company) | `entity.id` | Linked customer entity |
| `netsuite_contact_id` (from contact) | `contact.id` | Linked contact entity |
| - | `status` | Default: "Open" |
| - | `currency.id` | Default: "2" |
| - | `custbody14` | Custom field, default ID: "120" |

**NetSuite → HubSpot (Opportunity to Deal)**

| NetSuite Field | HubSpot Field | Notes |
|----------------|---------------|-------|
| `total` | `amount` | Opportunity total to deal amount |
| `probability` | `hs_deal_stage_probability` | Probability value |
| `expectedCloseDate` | `closedate` | Expected close date |
| `id` | `netsuite_opportunity_id` | NetSuite opportunity ID stored in HubSpot deal |

### Contact ↔ Contact

**HubSpot → NetSuite (Contact to Contact)**

| HubSpot Field | NetSuite Field | Notes |
|---------------|----------------|-------|
| `firstname` | `firstName` | First name |
| `lastname` | `lastName` | Last name |
| `email` | `email` | Email address |
| `jobtitle` | `jobTitle` | Job title |
| `phone` | `mobilePhone` | Phone number, default: "0000000000" if blank |
| `netsuite_company_id` (from company) | `company.id` | Linked customer entity |
| - | `isInactive` | Default: false |

**NetSuite → HubSpot (Contact to Contact)**

| NetSuite Field | HubSpot Field | Notes |
|----------------|---------------|-------|
| `firstName` | `firstname` | First name |
| `lastName` | `lastname` | Last name |
| `email` | `email` | Email address |
| `jobTitle` | `jobtitle` | Job title |
| `phone` | `phone` | Phone number |
| `id` | `netsuite_contact_id` | NetSuite contact ID stored in HubSpot contact |

### Company ↔ Customer

**HubSpot → NetSuite (Company to Customer)**

| HubSpot Field | NetSuite Field | Notes |
|---------------|----------------|-------|
| `name` | `companyName` | Company name |
| - | `subsidiary.id` | Default: "22" (Fortus USA) |
| - | `category.id` | Default: "13" (4. Competitor - DEKK) |
| - | `custentity11` | Custom field, default ID: "80" (Aston - FU) |

**NetSuite → HubSpot (Customer to Company)**

| NetSuite Field | HubSpot Field | Notes |
|----------------|---------------|-------|
| `name` | `name` | Company name |
| `id` | `netsuite_company_id` | NetSuite customer ID stored in HubSpot company |

### Quote Deal ↔ Estimate/Quote

**HubSpot → NetSuite (Deal to Estimate)**

| HubSpot Field | NetSuite Field | Notes |
|---------------|----------------|-------|
| `dealname` | `custbody_so_title` | Deal name to quote title |
| `netsuite_company_id` (from company) | `entity.id` | Linked customer entity |
| `netsuite_contact_id` (from contact) | `custbody1.id` | Contact custom field |
| `phone` (from contact) | `custbody_phone_number` | Delivery contact number |
| `netsuite_opportunity_id` | `opportunity.id` | Linked opportunity |
| - | `location.id` | Default: "80" |
| - | `custbody34` | Incident Date/Time (current UTC timestamp) |
| - | `custbody20.refName` | Origin, default: "Opportunity " |
| - | `custbody37.id` | Case Type, default: "6" |
| - | `item.items[0].item.id` | Default item ID: "2266" |
| - | `item.items[0].quantity` | Default: 1 |
| - | `item.items[0].rate` | Default: 500 |

**NetSuite → HubSpot (Estimate to Quote Deal)**

| NetSuite Field | HubSpot Field | Notes |
|----------------|---------------|-------|
| `title` | `dealname` | Estimate title to deal name |
| `total` | `amount` | Estimate total to deal amount |
| `terms` | `description` | Terms to deal description |
| `status` | `dealstage` | Status mapped to stage ID (Open: 1979552193, Closed Won: 1979552198, Closed Lost: 1979552199) |
| `id` | `netsuite_quote_id` | NetSuite estimate ID stored in HubSpot deal |

### Sales Order ↔ Order

**NetSuite → HubSpot (Sales Order to Order)**

| NetSuite Field | HubSpot Field | Notes |
|----------------|---------------|-------|
| `title` | `hs_order_name` | Order title |
| `trandate` | `hs_external_created_date` | Transaction date |
| `id` | `netsuite_order_number` | NetSuite order ID |
| `total` | `hs_total_price` | Order total |
| `orderStatus` | `hs_external_order_status` | Order status |
| `shipDate` | `ship_date` | Ship date |
| `status` | `hs_fulfillment_status` | Fulfillment status |
| `linkedTrackingNumbers` | `hs_shipping_tracking_number` | Tracking numbers |

**Associations:**
- Order → Contact (Association Type: 507)
- Order → Deal (Association Type: 512)
- Order → Company (Association Type: 509)

### Line Items

**NetSuite → HubSpot (Line Item to Line Item)**

| NetSuite Field | HubSpot Field | Notes |
|----------------|---------------|-------|
| `itemId` | `netsuite_item_id` | NetSuite item identifier |
| `quantity` | `quantity` | Item quantity |
| `amount` | `price` | Item price/amount |
| `description` | `description` | Item description |

**Line Item Associations:**
- Line Item → Deal (Association Type: `line_item_to_deal`)
- Line Item → Order (Association Type: `line_item_to_order`)

### Lookup Fields

**HubSpot Lookup Fields:**
- `netsuite_opportunity_id`: Links HubSpot deal to NetSuite opportunity
- `netsuite_quote_id`: Links HubSpot deal to NetSuite estimate
- `netsuite_company_id`: Links HubSpot company to NetSuite customer
- `netsuite_contact_id`: Links HubSpot contact to NetSuite contact
- `netsuite_order_number`: Links HubSpot order to NetSuite sales order
- `netsuite_item_id`: Links HubSpot line item to NetSuite item

**NetSuite Reference Fields:**
- `entity`: References customer/company
- `contact`: References contact
- `opportunity`: References opportunity
- `item.item`: References item/product

## References

- **Logging Standards**: See `LOGGING_STANDARDS.md` for detailed logging implementation guidelines
- **Papertrail Setup**: See `LOGGING_STANDARDS.md` for Papertrail configuration instructions
- **Technology Stack**: Ruby on Rails 8.0.2, PostgreSQL, HTTParty, Solid Queue, Solid Cache, Puma
