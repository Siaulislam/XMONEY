<?php

declare(strict_types=1);

namespace XMoney\Utils;

final class Validator
{
    /**
     * @param array<string, mixed> $data
     * @param array<string, string> $rules
     * @param array<string, string> $fieldLabels
     */
    public static function validate(array $data, array $rules, ?string $locale = null, array $fieldLabels = []): array
    {
        $errors = [];
        $labels = [];

        foreach ($rules as $field => $ruleString) {
            $rulesList = explode('|', $ruleString);
            $value = $data[$field] ?? null;
            $present = array_key_exists($field, $data) && $value !== null && $value !== '';
            $labels[$field] = $fieldLabels[$field] ?? I18n::t('field.' . $field, [], $locale);
            if ($labels[$field] === 'field.' . $field) {
                $labels[$field] = str_replace('_', ' ', $field);
            }

            foreach ($rulesList as $rule) {
                if ($rule === 'required' && !$present) {
                    $errors[$field][] = I18n::t('validation.required', ['field' => $labels[$field]], $locale);
                    break;
                }
                if (!$present) {
                    continue;
                }
                if ($rule === 'email' && !filter_var((string) $value, FILTER_VALIDATE_EMAIL)) {
                    $errors[$field][] = I18n::t('validation.email', ['field' => $labels[$field]], $locale);
                }
                if (str_starts_with($rule, 'min:')) {
                    $min = (int) substr($rule, 4);
                    if (is_string($value) && mb_strlen($value) < $min) {
                        $errors[$field][] = I18n::t('validation.min_chars', ['field' => $labels[$field], 'min' => $min], $locale);
                    }
                    if (is_numeric($value) && (float) $value < $min) {
                        $errors[$field][] = I18n::t('validation.min_number', ['field' => $labels[$field], 'min' => $min], $locale);
                    }
                }
                if (str_starts_with($rule, 'max:')) {
                    $max = (int) substr($rule, 4);
                    if (is_string($value) && mb_strlen($value) > $max) {
                        $errors[$field][] = I18n::t('validation.max_chars', ['field' => $labels[$field], 'max' => $max], $locale);
                    }
                }
                if ($rule === 'numeric' && !is_numeric($value)) {
                    $errors[$field][] = I18n::t('validation.numeric', ['field' => $labels[$field]], $locale);
                }
                if (str_starts_with($rule, 'in:')) {
                    $allowed = explode(',', substr($rule, 3));
                    if (!in_array((string) $value, $allowed, true)) {
                        $errors[$field][] = I18n::t('validation.in', ['field' => $labels[$field]], $locale);
                    }
                }
                if ($rule === 'password') {
                    $pwd = (string) $value;
                    if (
                        mb_strlen($pwd) < 8
                        || !preg_match('/[A-Z]/', $pwd)
                        || !preg_match('/[a-z]/', $pwd)
                        || !preg_match('/[0-9]/', $pwd)
                    ) {
                        $errors[$field][] = I18n::t('validation.password', [], $locale);
                    }
                }
            }
        }

        return $errors;
    }
}
