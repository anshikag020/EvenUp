package services

import (
    "fmt"
    "net/smtp"
    "os"
)

// SendMail sends a plain-text email to one or more recipients.
func SendMail(to []string, subject, body string) error {
    host := os.Getenv("SMTP_HOST")
    port := os.Getenv("SMTP_PORT")
    user := os.Getenv("SMTP_USER")
    pass := os.Getenv("SMTP_PASS")
    from := os.Getenv("EMAIL_FROM")

    auth := smtp.PlainAuth("", user, pass, host)
    addr := fmt.Sprintf("%s:%s", host, port)

    // Build RFC-822 style message
    msg := []byte(
        fmt.Sprintf("From: %s\r\n", from) +
            fmt.Sprintf("To: %s\r\n", to[0]) +
            fmt.Sprintf("Subject: %s\r\n", subject) +
            "\r\n" +
            body,
    )

    return smtp.SendMail(addr, auth, from, to, msg)
}
