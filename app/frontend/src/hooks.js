import { useCallback, useEffect, useState } from 'react'
import { message } from 'antd'
import { apiError } from './api'

// Resolves to the rows, or null when the request failed (already reported).
async function fetchRows(fetcher, errorMessage) {
  try {
    return await fetcher()
  } catch (error) {
    message.error(apiError(error, errorMessage))
    return null
  }
}

// Loads a collection and keeps it reloadable. Owns the loading flag (always
// cleared, so a failed request can never leave a table spinning) and surfaces
// errors as a toast instead of an unhandled rejection. State is only touched
// after the request settles, and never after unmount.
export function useCollection(fetcher, { errorMessage = 'Failed to load' } = {}) {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true
    ;(async () => {
      const data = await fetchRows(fetcher, errorMessage)
      if (!active) return

      if (data) setRows(data)
      setLoading(false)
    })()
    return () => {
      active = false
    }
  }, [fetcher, errorMessage])

  // Manual refresh: showing the spinner immediately is the point here.
  const reload = useCallback(async () => {
    setLoading(true)
    const data = await fetchRows(fetcher, errorMessage)
    if (data) setRows(data)
    setLoading(false)
  }, [fetcher, errorMessage])

  return { rows, loading, reload }
}

// Runs a mutation with consistent toasts; resolves to true on success so callers
// can branch. Never rejects — antd's Popconfirm re-throws rejections otherwise.
export async function mutate(promise, { success, error = 'Request failed', onDone } = {}) {
  try {
    await promise
    if (success) message.success(success)
    await onDone?.()
    return true
  } catch (e) {
    message.error(apiError(e, error))
    return false
  }
}
