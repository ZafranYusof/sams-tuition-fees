// Email service placeholder
// Configure with nodemailer when SMTP is ready

const sendEmail = async ({ to, subject, html }) => {
  // TODO: Configure SMTP transporter
  // const transporter = nodemailer.createTransport({...});
  // await transporter.sendMail({ from, to, subject, html });
  console.log(`[Email] Would send to ${to}: ${subject}`);
};

// Payment receipt email
exports.sendPaymentReceipt = async (userEmail, payment) => {
  await sendEmail({
    to: userEmail,
    subject: `Payment Receipt - ${payment.transactionId}`,
    html: `
      <h2>Payment Confirmation</h2>
      <p>Transaction ID: ${payment.transactionId}</p>
      <p>Amount: RM ${payment.amount.toFixed(2)}</p>
      <p>Method: ${payment.method.toUpperCase()}</p>
      <p>Status: ${payment.status}</p>
      <p>Date: ${new Date(payment.paidAt).toLocaleString('en-MY')}</p>
    `,
  });
};

// Fee reminder email
exports.sendFeeReminder = async (userEmail, fee) => {
  await sendEmail({
    to: userEmail,
    subject: `Fee Payment Reminder - Semester ${fee.semester}`,
    html: `
      <h2>Fee Payment Reminder</h2>
      <p>Outstanding: RM ${(fee.totalAmount - fee.paidAmount).toFixed(2)}</p>
      <p>Due Date: ${fee.dueDate ? new Date(fee.dueDate).toLocaleDateString('en-MY') : 'N/A'}</p>
      <p>Please make payment before the due date to avoid penalties.</p>
    `,
  });
};

// Overdue notification
exports.sendOverdueNotice = async (userEmail, fee) => {
  await sendEmail({
    to: userEmail,
    subject: `OVERDUE: Fee Payment - Semester ${fee.semester}`,
    html: `
      <h2>Overdue Fee Notice</h2>
      <p>Your fee payment is overdue.</p>
      <p>Outstanding: RM ${(fee.totalAmount - fee.paidAmount).toFixed(2)}</p>
      <p>Please make payment immediately.</p>
    `,
  });
};
