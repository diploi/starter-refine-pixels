<img alt="icon" src=".diploi/icon.svg" width="32">

# Collaborative Drawing App Starter Kit for Diploi

A fun, collaborative drawing app built with **Refine**, **React (Vite)**
and **Supabase**.

This starter kit demonstrates:

- 🔐 Authentication with Supabase
- 🎨 Realtime collaborative updates
- ⚡️ Vite-powered React frontend
- 🗄️ Supabase DB migrations and seeded data

---

## ✨ Overview

This starter kit consists of two Diploi components:

- **`react-vite`** -- Frontend application (Refine + React + Vite)
- **`supabase`** -- Database, auth, and realtime backend

Everything is wired together automatically via environment variables
defined in `diploi.yaml`.

---

## 🧱 Architecture

### 1️⃣ React (Vite) Component

Based on the official Diploi [react-vite](https://github.com/diploi/component-react-vite) component.

### Environment Variables

These are automatically injected from the Supabase component:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

This starter kit enables Diploi's **runtime build** mode:

    - name: __VITE_RUNTIME_BUILD
      value: true

This allows environment variables to be populated correctly in
production deployments.

---

### 2️⃣ Supabase Component

Based on the official Diploi [supabase](https://github.com/diploi/component-supabase) component.

The component automatically configures redirect URLs so authentication
flows correctly back to the React app.

---

## 🔑 Default Login Credentials

The database is seeded with a test account:

Email: `test@example.com`\
Password: `password`

You can log in immediately after deployment.

> ⚠️ Make sure to change or remove this account in production
> environments.

---

## 🚀 Running on Diploi

### Start a new project

1.  Create a new project in Diploi
2.  Select this starter kit
3.  Deploy

Diploi automatically:

- Connects Supabase to React
- Injects environment variables
- Configures networking
- Builds production images
- Enables edge delivery via Cloudflare

---

## 💡 About Refine

This project is originally based on the [Refine example template Pixels](https://refine.dev/core/templates/supabase-crud-app/) and
adapted for Diploi deployments.

Refine is a headless React framework for building CRUD applications:\
https://refine.dev
