# Notion Clone - API & Implementation Specifications

## Table of Contents
1. [API Endpoints](#api-endpoints)
2. [Database Schema](#database-schema)
3. [Real-Time Architecture](#real-time-architecture)
4. [Editor Implementation](#editor-implementation)
5. [Search & Indexing](#search--indexing)

---

## API Endpoints

### Authentication

#### `POST /api/auth/register`
Register a new user account.
```json
Request:
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe"
}

Response:
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "tokens": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```

#### `POST /api/auth/login`
Login to existing account.

#### `POST /api/auth/refresh`
Refresh access token.

#### `POST /api/auth/logout`
Logout and invalidate tokens.

---

### Workspace Management

#### `POST /api/workspaces`
Create a new workspace.
```json
Request:
{
  "name": "My Workspace",
  "icon": "🏢"
}
```

#### `GET /api/workspaces`
Get all workspaces for current user.

#### `GET /api/workspaces/:id`
Get specific workspace details.

#### `PATCH /api/workspaces/:id`
Update workspace settings.

#### `DELETE /api/workspaces/:id`
Delete workspace (soft delete).

---

### Pages

#### `POST /api/pages`
Create a new page.
```json
Request:
{
  "parent_id": "uuid",
  "parent_type": "page" | "workspace",
  "title": "My Page",
  "icon": "📄",
  "cover": {
    "type": "external",
    "url": "https://..."
  }
}

Response:
{
  "id": "uuid",
  "object": "page",
  "created_time": "2025-10-02T...",
  "parent": {...},
  "properties": {...}
}
```

#### `GET /api/pages/:id`
Get page details and metadata.

#### `GET /api/pages/:id/content`
Get page content (blocks).
```json
Response:
{
  "object": "list",
  "results": [
    {
      "id": "block_uuid",
      "type": "paragraph",
      "paragraph": {
        "rich_text": [...]
      }
    }
  ],
  "has_more": false,
  "next_cursor": null
}
```

#### `PATCH /api/pages/:id`
Update page properties (title, icon, cover, etc.).

#### `DELETE /api/pages/:id`
Archive a page.

#### `POST /api/pages/:id/restore`
Restore archived page.

---

### Blocks

#### `POST /api/blocks`
Create a new block.
```json
Request:
{
  "parent_id": "page_uuid",
  "type": "paragraph",
  "paragraph": {
    "rich_text": [
      {
        "type": "text",
        "text": { "content": "Hello world" },
        "annotations": {
          "bold": false,
          "italic": false,
          "code": false
        }
      }
    ]
  }
}
```

#### `GET /api/blocks/:id`
Get block details.

#### `GET /api/blocks/:id/children`
Get child blocks (nested content).

#### `PATCH /api/blocks/:id`
Update block content.
```json
Request:
{
  "paragraph": {
    "rich_text": [...]
  }
}
```

#### `DELETE /api/blocks/:id`
Delete a block.

#### `POST /api/blocks/:id/move`
Move block to new position.
```json
Request:
{
  "target_parent_id": "uuid",
  "target_position": "before" | "after" | "inside",
  "target_block_id": "uuid" (if before/after)
}
```

---

### Databases

#### `POST /api/databases`
Create a new database.
```json
Request:
{
  "parent_id": "page_uuid",
  "title": [{ "type": "text", "text": { "content": "Tasks" } }],
  "properties": {
    "Name": { "title": {} },
    "Status": {
      "select": {
        "options": [
          { "name": "Todo", "color": "red" },
          { "name": "Done", "color": "green" }
        ]
      }
    },
    "Due Date": { "date": {} }
  }
}
```

#### `GET /api/databases/:id`
Get database schema and configuration.

#### `GET /api/databases/:id/query`
Query database entries with filters and sorts.
```json
Request:
{
  "filter": {
    "property": "Status",
    "select": { "equals": "Todo" }
  },
  "sorts": [
    { "property": "Due Date", "direction": "ascending" }
  ]
}
```

#### `PATCH /api/databases/:id`
Update database schema (add/remove properties).

#### `POST /api/databases/:id/entries`
Create database entry (page in database).

---

### Comments

#### `POST /api/comments`
Add comment to page or block.
```json
Request:
{
  "parent_id": "uuid",
  "parent_type": "page" | "block",
  "rich_text": [
    {
      "type": "text",
      "text": { "content": "Great work!" }
    }
  ]
}
```

#### `GET /api/comments`
Get comments (filtered by parent).

---

### Search

#### `POST /api/search`
Search across workspace.
```json
Request:
{
  "query": "meeting notes",
  "filter": {
    "property": "object",
    "value": "page"
  },
  "sort": {
    "direction": "descending",
    "timestamp": "last_edited_time"
  }
}
```

---

### Users

#### `GET /api/users/me`
Get current user profile.

#### `GET /api/users/:id`
Get user by ID.

#### `GET /api/workspaces/:id/members`
Get workspace members.

#### `POST /api/workspaces/:id/members`
Invite user to workspace.

---

### Permissions

#### `POST /api/pages/:id/permissions`
Share page with user/team.
```json
Request:
{
  "user_id": "uuid",
  "role": "read" | "comment" | "write" | "full_access"
}
```

#### `GET /api/pages/:id/permissions`
Get page permissions list.

#### `DELETE /api/pages/:id/permissions/:permission_id`
Remove permission.

---

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE
);
```

### Workspaces Table
```sql
CREATE TABLE workspaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  icon TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE
);
```

### Workspace Members Table
```sql
CREATE TABLE workspace_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL, -- admin, member, guest
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(workspace_id, user_id)
);
```

### Pages Table
```sql
CREATE TABLE pages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  parent_id UUID, -- Can be page or workspace
  parent_type VARCHAR(20), -- 'page', 'workspace', 'database'
  title TEXT,
  icon TEXT,
  cover_url TEXT,
  is_full_width BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_edited_by UUID REFERENCES users(id),
  is_archived BOOLEAN DEFAULT FALSE,
  archived_at TIMESTAMP
);

CREATE INDEX idx_pages_workspace ON pages(workspace_id);
CREATE INDEX idx_pages_parent ON pages(parent_id);
CREATE INDEX idx_pages_updated ON pages(updated_at DESC);
```

### Blocks Table
```sql
CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_id UUID REFERENCES pages(id) ON DELETE CASCADE,
  parent_block_id UUID REFERENCES blocks(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  content JSONB NOT NULL, -- Block-specific content
  position INTEGER NOT NULL, -- Order within parent
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_edited_by UUID REFERENCES users(id),
  is_archived BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_blocks_page ON blocks(page_id);
CREATE INDEX idx_blocks_parent ON blocks(parent_block_id);
CREATE INDEX idx_blocks_position ON blocks(position);
CREATE INDEX idx_blocks_content ON blocks USING GIN(content);
```

### Databases Table
```sql
CREATE TABLE databases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  parent_id UUID,
  parent_type VARCHAR(20),
  title TEXT,
  description TEXT,
  icon TEXT,
  cover_url TEXT,
  properties JSONB NOT NULL, -- Schema definition
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE
);
```

### Database Views Table
```sql
CREATE TABLE database_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  database_id UUID REFERENCES databases(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- table, board, calendar, list, gallery, timeline
  configuration JSONB, -- View-specific config (filters, sorts, groups)
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  is_default BOOLEAN DEFAULT FALSE
);
```

### Comments Table
```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id UUID NOT NULL,
  parent_type VARCHAR(20) NOT NULL, -- 'page', 'block'
  discussion_id UUID NOT NULL, -- Group comments into threads
  content JSONB NOT NULL, -- Rich text content
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_comments_parent ON comments(parent_id, parent_type);
CREATE INDEX idx_comments_discussion ON comments(discussion_id);
```

### Permissions Table
```sql
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resource_id UUID NOT NULL,
  resource_type VARCHAR(20) NOT NULL, -- 'page', 'database'
  user_id UUID REFERENCES users(id),
  team_id UUID, -- For team-based permissions
  role VARCHAR(50) NOT NULL, -- read, comment, write, full_access
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  is_public BOOLEAN DEFAULT FALSE,
  public_password VARCHAR(255)
);

CREATE INDEX idx_permissions_resource ON permissions(resource_id, resource_type);
CREATE INDEX idx_permissions_user ON permissions(user_id);
```

### Activity Log Table
```sql
CREATE TABLE activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  action VARCHAR(50) NOT NULL, -- created, updated, deleted, shared, commented
  resource_id UUID NOT NULL,
  resource_type VARCHAR(20) NOT NULL,
  metadata JSONB, -- Additional action details
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activity_workspace ON activity_log(workspace_id, created_at DESC);
CREATE INDEX idx_activity_user ON activity_log(user_id, created_at DESC);
```

---

## Real-Time Architecture

### WebSocket Events

#### Client -> Server

**`join_page`**
```json
{
  "type": "join_page",
  "page_id": "uuid",
  "user_id": "uuid"
}
```

**`leave_page`**
```json
{
  "type": "leave_page",
  "page_id": "uuid"
}
```

**`block_update`**
```json
{
  "type": "block_update",
  "page_id": "uuid",
  "block_id": "uuid",
  "operation": {
    "type": "insert" | "delete" | "update",
    "path": [0, 5], // Character position
    "content": "text to insert",
    "version": 42
  }
}
```

#### Server -> Client

**`user_presence`**
```json
{
  "type": "user_presence",
  "page_id": "uuid",
  "users": [
    {
      "id": "uuid",
      "name": "John",
      "avatar": "url",
      "cursor_position": { "block_id": "uuid", "offset": 10 }
    }
  ]
}
```

**`block_changed`**
```json
{
  "type": "block_changed",
  "page_id": "uuid",
  "block_id": "uuid",
  "change": {
    "user_id": "uuid",
    "operation": {...},
    "version": 43
  }
}
```

**`comment_added`**
```json
{
  "type": "comment_added",
  "parent_id": "uuid",
  "comment": {...}
}
```

### Conflict Resolution Strategy

Use **Operational Transformation (OT)** or **CRDT (Yjs)**:

```javascript
// Using Yjs for collaborative editing
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';

const ydoc = new Y.Doc();
const provider = new WebsocketProvider(
  'wss://your-server.com',
  'page-uuid',
  ydoc
);

const ytext = ydoc.getText('content');

// Local changes automatically sync
ytext.insert(0, 'Hello ');

// Remote changes automatically merge
ydoc.on('update', (update) => {
  // Update UI
});
```

---

## Editor Implementation

### Block-Based Editor Architecture

```typescript
interface Block {
  id: string;
  type: BlockType;
  content: BlockContent;
  children: Block[];
  metadata: {
    createdAt: Date;
    updatedAt: Date;
    createdBy: string;
  };
}

type BlockType =
  | 'paragraph'
  | 'heading_1'
  | 'heading_2'
  | 'heading_3'
  | 'bulleted_list'
  | 'numbered_list'
  | 'to_do'
  | 'toggle'
  | 'code'
  | 'quote'
  | 'callout'
  | 'image'
  | 'video'
  | 'file'
  | 'bookmark'
  | 'table'
  | 'database';

interface RichText {
  type: 'text';
  text: {
    content: string;
    link?: { url: string };
  };
  annotations: {
    bold: boolean;
    italic: boolean;
    strikethrough: boolean;
    underline: boolean;
    code: boolean;
    color: string;
  };
}
```

### Slash Commands Implementation

```typescript
const slashCommands = [
  { trigger: '/h1', label: 'Heading 1', action: 'insert_heading_1' },
  { trigger: '/h2', label: 'Heading 2', action: 'insert_heading_2' },
  { trigger: '/h3', label: 'Heading 3', action: 'insert_heading_3' },
  { trigger: '/todo', label: 'To-do list', action: 'insert_todo' },
  { trigger: '/bullet', label: 'Bulleted list', action: 'insert_bullet' },
  { trigger: '/code', label: 'Code block', action: 'insert_code' },
  { trigger: '/table', label: 'Table', action: 'insert_table' },
  { trigger: '/image', label: 'Image', action: 'insert_image' },
  { trigger: '/database', label: 'Database', action: 'insert_database' },
];

function handleSlashCommand(query: string) {
  return slashCommands.filter(cmd =>
    cmd.label.toLowerCase().includes(query.toLowerCase())
  );
}
```

### Drag & Drop Implementation

```typescript
// Using react-beautiful-dnd or dnd-kit

function onDragEnd(result: DropResult) {
  const { source, destination } = result;
  
  if (!destination) return;
  
  // Reorder blocks
  const sourceBlock = blocks[source.index];
  const newBlocks = Array.from(blocks);
  newBlocks.splice(source.index, 1);
  newBlocks.splice(destination.index, 0, sourceBlock);
  
  // Update positions in database
  await updateBlockPositions(newBlocks);
  
  setBlocks(newBlocks);
}
```

---

## Search & Indexing

### Elasticsearch Schema

```json
{
  "mappings": {
    "properties": {
      "id": { "type": "keyword" },
      "type": { "type": "keyword" },
      "workspace_id": { "type": "keyword" },
      "title": {
        "type": "text",
        "analyzer": "standard",
        "fields": {
          "keyword": { "type": "keyword" }
        }
      },
      "content": {
        "type": "text",
        "analyzer": "standard"
      },
      "created_by": { "type": "keyword" },
      "created_at": { "type": "date" },
      "updated_at": { "type": "date" },
      "tags": { "type": "keyword" },
      "parent_ids": { "type": "keyword" }
    }
  }
}
```

### Indexing Strategy

```typescript
// Index page when created/updated
async function indexPage(page: Page) {
  const content = await extractTextFromBlocks(page.blocks);
  
  await elasticsearchClient.index({
    index: 'pages',
    id: page.id,
    document: {
      id: page.id,
      type: 'page',
      workspace_id: page.workspaceId,
      title: page.title,
      content: content,
      created_by: page.createdBy,
      created_at: page.createdAt,
      updated_at: page.updatedAt,
      tags: extractTags(page),
      parent_ids: getParentHierarchy(page)
    }
  });
}

// Search with fuzzy matching
async function search(query: string, workspaceId: string) {
  return await elasticsearchClient.search({
    index: 'pages',
    body: {
      query: {
        bool: {
          must: [
            { term: { workspace_id: workspaceId } },
            {
              multi_match: {
                query: query,
                fields: ['title^3', 'content'],
                fuzziness: 'AUTO'
              }
            }
          ]
        }
      },
      highlight: {
        fields: {
          title: {},
          content: {}
        }
      }
    }
  });
}
```

---

## File Upload & Storage

### Upload Flow

```typescript
// 1. Client requests signed URL
POST /api/files/upload-url
Request: { filename: 'image.png', content_type: 'image/png' }
Response: { 
  upload_url: 'https://s3...', 
  file_id: 'uuid',
  download_url: 'https://cdn...'
}

// 2. Client uploads directly to S3
PUT <upload_url>
Body: <file_binary>

// 3. Client confirms upload
POST /api/files/:file_id/confirm
Response: { status: 'success' }
```

### Storage Implementation

```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

async function generateUploadUrl(
  filename: string,
  contentType: string
): Promise<UploadInfo> {
  const fileId = generateUUID();
  const key = `uploads/${fileId}/${filename}`;
  
  const command = new PutObjectCommand({
    Bucket: 'notion-clone-files',
    Key: key,
    ContentType: contentType
  });
  
  const uploadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: 3600 // 1 hour
  });
  
  return {
    fileId,
    uploadUrl,
    downloadUrl: `https://cdn.yourapp.com/${key}`
  };
}
```

---

## Caching Strategy

### Redis Cache Layers

```typescript
// Page metadata cache (1 hour TTL)
await redis.setex(
  `page:${pageId}:metadata`,
  3600,
  JSON.stringify(pageMetadata)
);

// Block content cache (5 minutes TTL)
await redis.setex(
  `page:${pageId}:blocks`,
  300,
  JSON.stringify(blocks)
);

// User sessions (24 hours TTL)
await redis.setex(
  `session:${userId}`,
  86400,
  JSON.stringify(sessionData)
);

// Workspace members (1 hour TTL)
await redis.setex(
  `workspace:${workspaceId}:members`,
  3600,
  JSON.stringify(members)
);
```

---

## Performance Optimization

### Pagination

```typescript
// Cursor-based pagination for blocks
GET /api/pages/:id/content?cursor=block_uuid&limit=50

Response: {
  results: [...],
  has_more: true,
  next_cursor: 'next_block_uuid'
}
```

### Lazy Loading

- Load blocks in viewport only
- Virtualized scrolling for long pages
- Image lazy loading with placeholders
- Database view lazy rendering

### Database Query Optimization

```sql
-- Partial indexes for common queries
CREATE INDEX idx_pages_workspace_active 
ON pages(workspace_id) 
WHERE is_archived = FALSE;

-- Covering index for page list queries
CREATE INDEX idx_pages_list 
ON pages(workspace_id, updated_at DESC, id) 
INCLUDE (title, icon);
```

---

## Security Best Practices

1. **Authentication**: JWT with short expiry (15 min) + refresh tokens
2. **Authorization**: Check permissions on every API call
3. **Input Validation**: Sanitize all user inputs
4. **Rate Limiting**: 100 requests/minute per user
5. **CORS**: Whitelist specific domains
6. **SQL Injection**: Use parameterized queries
7. **XSS Prevention**: Sanitize rich text content
8. **File Upload**: Validate file types, scan for malware
9. **Encryption**: TLS 1.3 for transit, AES-256 at rest

---

## Monitoring & Observability

### Key Metrics to Track

- API response times (P50, P95, P99)
- WebSocket connection count
- Real-time sync latency
- Database query performance
- Search query latency
- File upload/download speeds
- Error rates by endpoint
- User active sessions

### Logging Structure

```json
{
  "timestamp": "2025-10-02T12:00:00Z",
  "level": "info",
  "service": "api",
  "user_id": "uuid",
  "workspace_id": "uuid",
  "endpoint": "/api/pages",
  "method": "POST",
  "duration_ms": 45,
  "status": 201,
  "trace_id": "uuid"
}
```

---

## Testing Strategy

1. **Unit Tests**: Individual functions and utilities
2. **Integration Tests**: API endpoints with database
3. **E2E Tests**: Full user flows (Playwright/Cypress)
4. **Performance Tests**: Load testing with k6
5. **Security Tests**: OWASP ZAP scans

---

This specification provides a complete technical blueprint for building a production-ready Notion clone. Each section can be expanded based on specific requirements and team preferences.

