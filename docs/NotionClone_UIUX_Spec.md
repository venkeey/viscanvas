# NotionClone UI/UX Specification

## Sources
- Reference walkthrough video: [YouTube link](https://www.youtube.com/watch?v=kOf3QSBV29Y)
- Functional specs: `NotionCloneSpecs.md`
- API specs: `NotionClone_API_Specs.md`

## Information Architecture (IA)
- Workspaces
  - Sidebar
    - Favorites
    - Recents
    - Shared
    - Private
    - Teams/Spaces
  - Root: All pages and databases
- Pages
  - Content blocks (hierarchical)
  - Child pages
  - Inline databases
- Databases
  - Views (table, board, calendar, list, gallery, timeline)
  - Entries (pages)
- Search
- Templates
- Settings & Members

## Primary Flows
1. Create page (from sidebar, from template, inline)
2. Edit page content (blocks, drag & drop, slash commands)
3. Create database and add views
4. Edit database properties and entries
5. Share page/workspace (set permissions)
6. Comment and mention (@)
7. Search and navigate (quick find, cmd/ctrl+P)

## Key Screens
- App Shell
  - Topbar: search, quick actions, breadcrumbs, share button, avatar
  - Sidebar: collapsible, resizable, hover-reveal actions
  - Canvas: page or database view
- Page Screen
  - Title area with icon/cover controls
  - Block editor area
  - Comments drawer (right)
- Database Screen
  - Title, description
  - View tabs + view toolbar (filter, sort, group, properties, new view)
  - Grid/Board/Calendar/List/Gallery/Timeline canvases

## Interaction Patterns
- Editor
  - Slash commands: '/' opens command palette filtered by query
  - Rich text inline toolbar (bold, italic, underline, code, link, color)
  - Drag handle on block hover for reorder and nesting
  - Enter creates new block, Shift+Enter new line
  - Backspace on empty block merges with previous
  - Transform block (e.g., paragraph -> heading) via menu or shortcut
- Databases
  - Inline cell editing with type-aware inputs
  - Column resize, reorder via drag
  - Add property from header '+'
  - View toolbar: filter chips, sort chips, group selector
  - Kanban: drag cards between groups
  - Calendar: drag to create/edit date ranges
- Navigation
  - Cmd/Ctrl+P quick switcher with fuzzy search
  - Breadcrumbs clickable for parent navigation
  - Sidebar: hover to reveal add, menu, drag
- Sharing & Comments
  - Share button opens modal: people/teams, roles, public link
  - Comment on block via side handle or selection
  - @mentions support users and pages

## States
- Empty, Loading, Error, Offline, Permissions
  - Covered in detail above with copy and UI behaviors

## Deliverables
- Wireframes (low-fi) for: App Shell, Page, Database (Table/Board/Calendar)
- Interaction prototypes: Slash menu, block drag, view toolbar
- Component specs: Props, variants, states

## Handoff Checklist
- Component inventory with tokens mapped
- Redlines for spacing/typography
- Keyboard navigation map
- Accessibility annotations per screen

## Keyboard Shortcuts
- Global
  - Cmd/Ctrl+P: Quick switcher
  - Cmd/Ctrl+N: New page
  - Cmd/Ctrl+Shift+P: Command palette
- Editor
  - Cmd/Ctrl+B/I/U: Bold/Italic/Underline
  - Cmd/Ctrl+K: Insert link
  - Cmd/Ctrl+Shift+S: Strikethrough
  - Tab/Shift+Tab: Indent/Outdent block
  - Cmd/Ctrl+Shift+M: Comment on selection

## Accessibility
- Focus outlines for all interactive elements
- ARIA roles for editor blocks and toolbars
- Keyboard operability for drag-and-drop via move up/down and indent controls
- Color contrast ≥ 4.5:1; motion reduce preference respected
- Screen reader labels: block type, position, nesting

## Motion & Micro-interactions
- Subtle fade/slide for block insertion and reordering
- Snackbar toasts for actions (undo available)
- Sticky toolbars appear on focus/hover, disappear on blur

## Visual Design Tokens

### Typography
- Font families
  - Primary: "Inter", "SF Pro Text", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif
  - Monospace (code): "SFMono-Regular", Menlo, Consolas, "Liberation Mono", monospace
- Font sizes (px) and line-heights
  - Display: 32 / 40 (weight 600)
  - H1: 24 / 32 (600)
  - H2: 20 / 28 (600)
  - H3: 18 / 26 (600)
  - Body: 16 / 24 (400)
  - Small: 14 / 20 (400)
  - Caption: 12 / 16 (400)
- Letter-spacing
  - Headings: 0
  - Body: 0
  - Caption: 0.005em
- Weights: 400, 500, 600

### Color Palette
- Neutral (Gray)
  - 50:  #F9FAFB
  - 100: #F3F4F6
  - 200: #E5E7EB
  - 300: #D1D5DB
  - 400: #9CA3AF
  - 500: #6B7280
  - 600: #4B5563
  - 700: #374151
  - 800: #1F2937
  - 900: #111827
- Primary (Indigo)
  - 50:  #EEF2FF
  - 100: #E0E7FF
  - 200: #C7D2FE
  - 300: #A5B4FC
  - 400: #818CF8
  - 500: #6366F1
  - 600: #4F46E5
  - 700: #4338CA
  - 800: #3730A3
  - 900: #312E81
- Accent (Teal)
  - 500: #14B8A6, 600: #0D9488
- Semantic
  - Success:  #10B981
  - Warning:  #F59E0B
  - Danger:   #EF4444
  - Info:     #3B82F6
- Application colors
  - Text primary:        #111827
  - Text secondary:      #4B5563
  - Text muted:          #6B7280
  - Link:                #4F46E5
  - Border:              #E5E7EB
  - Surface:             #FFFFFF
  - Surface-subtle:      #F9FAFB
  - Surface-elevated:    #FFFFFF
  - Canvas (editor bg):  #FFFFFF
  - Overlay scrim:       rgba(17,24,39,0.5)

### Spacing Scale (px)
- 0, 2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64
- Defaults
  - Grid base: 4
  - Page padding: 24
  - Section gap: 24
  - Element gap: 8–12

### Radii
- None: 0
- Sm: 4
- Md: 6 (default controls)
- Lg: 8 (cards)
- Xl: 12 (modals, large surfaces)

### Shadows (CSS)
- Level 1: 0 1px 2px rgba(17,24,39,0.06), 0 1px 1px rgba(17,24,39,0.04)
- Level 2: 0 10px 15px rgba(17,24,39,0.1), 0 4px 6px rgba(17,24,39,0.05)
- Focus ring: 0 0 0 3px rgba(99,102,241,0.35)

### Breakpoints (px)
- xs: 360
- sm: 640
- md: 768
- lg: 1024
- xl: 1280
- xxl: 1536

### Component Sizing
- Topbar height: 48
- Sidebar width: 260 (resizable 200–320)
- Editor max width: 900 (with 24 side padding)
- Modal widths: sm 360, md 560, lg 720
- Icon sizes: 16, 20, 24
- Hit area min: 40x40

### Motion
- Durations (ms): 100, 150, 200, 300
- Easing: cubic-bezier(0.2, 0, 0, 1)
- Reduce motion: disable non-essential transitions

### Token Names (Web CSS variables)
```css
:root{
  --font-sans: "Inter", "SF Pro Text", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
  --font-mono: "SFMono-Regular", Menlo, Consolas, "Liberation Mono", monospace;

  --fs-display: 32px; --lh-display: 40px; --fw-display: 600;
  --fs-h1: 24px; --lh-h1: 32px; --fw-h1: 600;
  --fs-h2: 20px; --lh-h2: 28px; --fw-h2: 600;
  --fs-h3: 18px; --lh-h3: 26px; --fw-h3: 600;
  --fs-body: 16px; --lh-body: 24px; --fw-body: 400;
  --fs-small: 14px; --lh-small: 20px; --fw-small: 400;
  --fs-caption: 12px; --lh-caption: 16px; --fw-caption: 400;

  --color-text: #111827; --color-text-2: #4B5563; --color-text-3: #6B7280;
  --color-link: #4F46E5; --color-border: #E5E7EB; --color-surface: #FFFFFF;
  --color-surface-subtle: #F9FAFB; --color-overlay: rgba(17,24,39,0.5);

  --primary-500:#6366F1; --primary-600:#4F46E5; --primary-700:#4338CA;
  --success:#10B981; --warning:#F59E0B; --danger:#EF4444; --info:#3B82F6;

  --radius-sm:4px; --radius-md:6px; --radius-lg:8px; --radius-xl:12px;
  --shadow-1:0 1px 2px rgba(17,24,39,0.06), 0 1px 1px rgba(17,24,39,0.04);
  --shadow-2:0 10px 15px rgba(17,24,39,0.1), 0 4px 6px rgba(17,24,39,0.05);

  --topbar-h:48px; --sidebar-w:260px; --editor-max-w:900px;
}
```

## Component Library
- Shell
  - AppSidebar (resizable), AppTopbar, Breadcrumbs
- Editor
  - BlockRenderer, InlineToolbar, SlashMenu, DragHandle, MentionPicker
- Database
  - ViewTabs, ViewToolbar, GridCell, KanbanColumn, CalendarGrid, GalleryCard
- Shared
  - Modal, Dropdown, Tooltip, Toast, Avatar, Tag, Pill, EmptyState, Skeleton

## Success Metrics
- Editor latency: < 16ms per keystroke (P95)
- Block reordering: < 50ms visual response
- Initial page load: < 2s on 3G fast
- Quick switcher results: < 150ms

## Open Questions
- Template system scope for MVP
- Version history depth and UI surfacing
- Offline conflict resolution UI

## References
- Video walkthrough: [YouTube](https://www.youtube.com/watch?v=kOf3QSBV29Y)
- Functional spec: `NotionCloneSpecs.md`
- API spec: `NotionClone_API_Specs.md`
