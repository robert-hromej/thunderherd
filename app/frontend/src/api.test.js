import { describe, test, expect } from 'vitest'
import { apiError } from './api'

describe('apiError', () => {
  test('unwraps a single {error} string', () => {
    expect(apiError({ response: { data: { error: 'run #1 is still running' } } })).toBe(
      'run #1 is still running',
    )
  })

  test('joins an {errors: []} array', () => {
    expect(apiError({ response: { data: { errors: ['Name is required', 'URL is invalid'] } } })).toBe(
      'Name is required, URL is invalid',
    )
  })

  test('falls back when the response carries no detail', () => {
    expect(apiError(new Error('network down'), 'Delete failed')).toBe('Delete failed')
    expect(apiError(undefined)).toBe('Request failed')
    expect(apiError({ response: { data: {} } }, 'Save failed')).toBe('Save failed')
  })
})
