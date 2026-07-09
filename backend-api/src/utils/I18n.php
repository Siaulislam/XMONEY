<?php

declare(strict_types=1);

namespace XMoney\Utils;

final class I18n
{
    /** @var array<string, array<string, string>> */
    private static array $catalogCache = [];

    public static function locale(?array $request = null): string
    {
        $candidates = [];

        if ($request) {
            $candidates[] = $request['body']['locale'] ?? null;
            $candidates[] = $request['query']['locale'] ?? null;
            $candidates[] = $request['user']['preferred_language'] ?? null;
            $candidates[] = $request['admin']['preferred_language'] ?? null;
        }

        $candidates[] = $_SERVER['HTTP_X_LOCALE'] ?? null;
        $candidates[] = $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? null;

        foreach ($candidates as $candidate) {
            $locale = self::normalizeLocale(is_string($candidate) ? $candidate : null);
            if ($locale !== null) {
                return $locale;
            }
        }

        return 'en';
    }

    public static function t(string $key, array $params = [], ?string $locale = null): string
    {
        $locale = self::normalizeLocale($locale) ?? 'en';
        $catalog = self::catalog($locale);
        $fallback = self::catalog('en');
        $value = $catalog[$key] ?? $fallback[$key] ?? $key;

        foreach ($params as $param => $replacement) {
            $value = str_replace('{' . $param . '}', (string) $replacement, $value);
        }

        return $value;
    }

    /**
     * @param array<string, string> $fields
     * @return array<string, string>
     */
    public static function fieldLabels(array $fields, ?string $locale = null): array
    {
        $labels = [];
        foreach ($fields as $field => $fallback) {
            $labels[$field] = self::t('field.' . $field, [], $locale);
            if ($labels[$field] === 'field.' . $field) {
                $labels[$field] = $fallback;
            }
        }
        return $labels;
    }

    /**
     * @return array<string, string>
     */
    private static function catalog(string $locale): array
    {
        if (isset(self::$catalogCache[$locale])) {
            return self::$catalogCache[$locale];
        }

        $path = dirname(__DIR__) . '/Locales/' . $locale . '.php';
        if (!is_file($path)) {
            $path = dirname(__DIR__) . '/Locales/en.php';
        }

        /** @var array<string, string> $catalog */
        $catalog = require $path;
        self::$catalogCache[$locale] = $catalog;
        return $catalog;
    }

    private static function normalizeLocale(?string $value): ?string
    {
        if (!$value) {
            return null;
        }

        $trimmed = strtolower(trim(explode(',', $value)[0] ?? ''));
        $code = substr(str_replace('_', '-', $trimmed), 0, 2);
        return in_array($code, ['en', 'ar', 'ur'], true) ? $code : null;
    }
}
