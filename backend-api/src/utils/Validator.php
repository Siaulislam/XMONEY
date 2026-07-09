<?php

declare(strict_types=1);

namespace XMoney\Utils;

final class Validator
{
    /** @param array<string, mixed> $data @param array<string, string> $rules */
    public static function validate(array $data, array $rules): array
    {
        $errors = [];

        foreach ($rules as $field => $ruleString) {
            $rulesList = explode('|', $ruleString);
            $value = $data[$field] ?? null;
            $present = array_key_exists($field, $data) && $value !== null && $value !== '';

            foreach ($rulesList as $rule) {
                if ($rule === 'required' && !$present) {
                    $errors[$field][] = "{$field} is required";
                    break;
                }
                if (!$present) {
                    continue;
                }
                if ($rule === 'email' && !filter_var((string) $value, FILTER_VALIDATE_EMAIL)) {
                    $errors[$field][] = "{$field} must be a valid email";
                }
                if (str_starts_with($rule, 'min:')) {
                    $min = (int) substr($rule, 4);
                    if (is_string($value) && mb_strlen($value) < $min) {
                        $errors[$field][] = "{$field} must be at least {$min} characters";
                    }
                    if (is_numeric($value) && (float) $value < $min) {
                        $errors[$field][] = "{$field} must be at least {$min}";
                    }
                }
                if (str_starts_with($rule, 'max:')) {
                    $max = (int) substr($rule, 4);
                    if (is_string($value) && mb_strlen($value) > $max) {
                        $errors[$field][] = "{$field} must be at most {$max} characters";
                    }
                }
                if ($rule === 'numeric' && !is_numeric($value)) {
                    $errors[$field][] = "{$field} must be numeric";
                }
                if (str_starts_with($rule, 'in:')) {
                    $allowed = explode(',', substr($rule, 3));
                    if (!in_array((string) $value, $allowed, true)) {
                        $errors[$field][] = "{$field} is invalid";
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
                        $errors[$field][] = 'Password must be 8+ chars with upper, lower, and number';
                    }
                }
            }
        }

        return $errors;
    }
}
