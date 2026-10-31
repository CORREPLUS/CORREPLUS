# CORREPLUS CRM

Sistema de gestión de CORREPLUS Corredores de Seguros: clientes, pólizas, cobros, comisiones, siniestros, reportes y documentos.

- **Datos y usuarios:** [Supabase](https://supabase.com) (base de datos Postgres + login con correo y contraseña).
- **Página:** un solo `index.html`, sin compilación. Se publica en Vercel (o cualquier hosting estático).

## Archivos

| Archivo | Para qué |
|---|---|
| `index.html` | El sistema completo |
| `config.js` | URL y clave pública (anon) del proyecto de Supabase |
| `vendor/supabase.js` | Librería de Supabase (copia local, no depende de CDN) |
| `supabase/instalar.sql` | Crea las tablas, la seguridad y los cambios en vivo |

## Instalación (una sola vez)

1. **Supabase:** crear el proyecto. En *SQL Editor* pegar `supabase/instalar.sql` y darle *Run*.
2. **Supabase › Authentication › URL Configuration:** en *Site URL* poner la dirección donde quedará el sistema (ej. `https://correplus-crm.vercel.app`).
3. **`config.js`:** poner el *Project URL* y la clave *anon public* (Project Settings › API). Nunca la `service_role`.
4. **Vercel:** *Add New › Project*, importar este repositorio, sin framework ni comando de build. Cada cambio en `main` se publica solo.

## Primer uso

1. Abrir el sistema y tocar **Primera vez: crear mi contraseña** con el correo del administrador. El primero que entra a un sistema vacío queda como **Administrador**.
2. Para pasar los datos que ya existen: en la versión anterior ir a *Respaldo de datos › Descargar respaldo*, y en el sistema nuevo *Respaldo de datos › Restaurar respaldo*.
3. Agregar a cada empleado en **Configuración › Usuarios** con su correo y rol. Tocando lo que dice *Puede* se ajusta a qué módulos entra y si solo ve o también edita. Luego el empleado entra con *Primera vez: crear mi contraseña* usando ese correo.

## Seguridad

- Sin un usuario activo en *Configuración › Usuarios*, la base de datos no entrega nada (reglas RLS en `instalar.sql`).
- Solo un Administrador puede cambiar la lista de usuarios.
- Los permisos por módulo (ver / editar / sin acceso) se aplican en la pantalla.
- Los archivos adjuntos a pólizas todavía se guardan en la computadora donde se suben.
