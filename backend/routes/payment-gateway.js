1|const express = require('express');
2|const crypto = require('crypto');
3|const https = require('https');
4|const axios = require('axios');
5|const mongoose = require('mongoose');
6|const Fee = require('../models/ManageTuitionFees/Fee');
7|const Payment = require('../models/ManageTuitionFees/Payment');
8|const { auth } = require('../middleware/auth');
9|
10|const router = express.Router();
11|
12|// ─── TOYYIBPAY (FPX) ───
13|
14|// Create FPX payment bill
15|router.post('/fpx/create', auth, async (req, res) => {
16|  try {
17|    const { feeId, amount, description, bank } = req.body;
18|    if (!feeId || !mongoose.Types.ObjectId.isValid(feeId)) {
19|      return res.status(400).json({ error: 'Invalid fee ID' });
20|    }
21|    if (!amount || amount <= 0) {
22|      return res.status(400).json({ error: 'Invalid amount' });
23|    }
24|    const Student = require('../models/Student');
25|    
26|    const fee = await Fee.findById(feeId);
27|    if (!fee) return res.status(404).json({ error: 'Fee not found' });
28|
29|    // Get full user info from DB
30|    const student = await Student.findById(req.user.id);
31|
32|    const billData = new URLSearchParams({
33|      userSecretKey: process.env.TOYYIBPAY_SECRET_KEY,
34|      categoryCode: process.env.TOYYIBPAY_CATEGORY_CODE,
35|      billName: description || 'UMPSA Tuition Fee Payment',
36|      billDescription: `Fee payment for ${feeId}`,
37|      billPriceSetting: 1,
38|      billPayorInfo: 1,
39|      billAmount: Math.round(amount * 100), // in cents
40|      billReturnUrl: `${process.env.APP_URL || 'https://sams-app-vasb.onrender.com'}/api/payment/fpx/callback`,
41|      billCallbackUrl: `${process.env.APP_URL || 'https://sams-app-vasb.onrender.com'}/api/payment/fpx/webhook`,
42|      billExternalReferenceNo: `FPX-${feeId}-${Date.now()}`,
43|      billTo: student?.studName || 'Student',
44|      billEmail: student?.studEmail || 'student@umpsa.edu.my',
45|      billPhone: student?.phone || '0111111111',
46|      billPaymentChannel: 0, // FPX only
47|    });
48|
49|    const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com'; // dev = sandbox
50|    
51|    const response = await fetch(`${baseUrl}/index.php/api/createBill`, {
52|      method: 'POST',
53|      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
54|      body: billData.toString(),
55|    });
56|
57|    const result = await response.json();
58|
59|    if (result && result[0] && result[0].BillCode) {
60|      // Save pending payment
61|      const payment = new Payment({
62|        student: req.user.id,
63|        fee: feeId,
64|        paymentAmount: amount,
65|        paymentMethod: 'fpx',
66|        paymentTxnRef: result[0].BillCode,
67|        bank: bank || 'FPX',
68|        paymentStatus: 'pending',
69|      });
70|      await payment.save();
71|
72|      res.json({
73|        billCode: result[0].BillCode,
74|        paymentUrl: `${baseUrl}/${result[0].BillCode}`,
75|        payment: payment,
76|      });
77|    } else {
78|      res.status(400).json({ error: 'Failed to create bill', details: result });
79|    }
80|  } catch (err) {
81|    res.status(500).json({ error: err.message });
82|  }
83|});
84|
85|// FPX callback (redirect after payment)
86|router.get('/fpx/callback', async (req, res) => {
87|  try {
88|    const { billcode, status_id, transaction_id, order_id } = req.query;
89|    
90|    const payment = await Payment.findOne({ paymentTxnRef: billcode });
91|    if (payment && payment.paymentStatus === 'pending') {
92|      // status_id: 1 = success, 2 = pending, 3 = failed
93|      if (status_id === '1') {
94|        payment.paymentStatus = 'success';
95|        payment.receipt = `RCP-${Date.now()}`;
96|
97|        // Fetch real bank name from ToyibPay
98|        try {
99|          const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com';
100|          const txnResp = await axios.post(`${baseUrl}/index.php/api/getBillTransactions`, {
101|            billCode: billcode,
102|            billpaymentStatus: '1',
103|          }, { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
104|          if (Array.isArray(txnResp.data) && txnResp.data.length > 0) {
105|            const channel = txnResp.data[0].billpaymentChannel || txnResp.data[0].billpaymentChannelName;
106|            if (channel) {
107|              payment.bank = mapChannelToBank(channel);
108|            }
109|          }
110|        } catch (e) {
111|          console.warn('Failed to fetch bank info from ToyibPay:', e.message);
112|        }
113|
114|        await payment.save();
115|
116|        // Update fee atomically, cap at totalAmount
117|        const fee = await Fee.findById(payment.fee);
118|        if (fee && fee.feeStatus !== 'paid') {
119|          const remaining = fee.feeAmount - fee.paidAmount;
120|          const actualAmount = Math.min(payment.paymentAmount, remaining);
121|          await Fee.findOneAndUpdate(
122|            { _id: payment.fee },
123|            {
124|              $inc: { paidAmount: actualAmount },
125|              $set: { status: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
126|            }
127|          );
128|        }
129|      } else if (status_id === '3') {
130|        payment.paymentStatus = 'failed';
131|        await payment.save();
132|      }
133|    }
134|
135|    // Redirect to app (deep link or web)
136|    const redirectUrl = status_id === '1' 
137|      ? `samsapp://payment/success?billcode=${billcode}`
138|      : `samsapp://payment/failed?billcode=${billcode}`;
139|    
140|    res.redirect(redirectUrl);
141|  } catch (err) {
142|    console.error('FPX callback error:', err.message);
143|    res.redirect('samsapp://payment/failed');
144|  }
145|});
146|
147|// Map ToyibPay channel name to friendly bank name
148|function mapChannelToBank(channel) {
149|  const c = (channel || '').toLowerCase();
150|  if (c.includes('maybank')) return 'Maybank';
151|  if (c.includes('cimb')) return 'CIMB';
152|  if (c.includes('rhb')) return 'RHB';
153|  if (c.includes('public')) return 'Public Bank';
154|  if (c.includes('hong leong') || c.includes('hongleong')) return 'Hong Leong';
155|  if (c.includes('islam')) return 'Bank Islam';
156|  if (c.includes('ambank') || c.includes('am ')) return 'AmBank';
157|  if (c.includes('alliance')) return 'Alliance';
158|  if (c.includes('uob')) return 'UOB';
159|  if (c.includes('ocbc')) return 'OCBC';
160|  if (c.includes('hsbc')) return 'HSBC';
161|  if (c.includes('rakyat')) return 'Bank Rakyat';
162|  if (c.includes('muamalat')) return 'Bank Muamalat';
163|  if (c.includes('agro')) return 'Agrobank';
164|  if (c.includes('affin')) return 'Affin Bank';
165|  // Filter out generic FPX channel names (sandbox/dev returns "FPX B2C")
166|  if (c.includes('fpx') || c.includes('b2c') || c.includes('b2b')) return 'Online Banking';
167|  return channel || 'Online Banking'; // fallback
168|}
169|
170|// FPX webhook (server-to-server callback)
171|router.post('/fpx/webhook', async (req, res) => {
172|  try {
173|    const { billcode, status_id, transaction_id } = req.body;
174|    
175|    const payment = await Payment.findOne({ paymentTxnRef: billcode });
176|    if (payment && payment.paymentStatus === 'pending') {
177|      if (status_id === '1') {
178|        payment.paymentStatus = 'success';
179|        payment.receipt = `RCP-${Date.now()}`;
180|
181|        // Fetch real bank from ToyibPay
182|        try {
183|          const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com';
184|          const txnResp = await axios.post(`${baseUrl}/index.php/api/getBillTransactions`, {
185|            billCode: billcode,
186|            billpaymentStatus: '1',
187|          }, { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
188|          if (Array.isArray(txnResp.data) && txnResp.data.length > 0) {
189|            const channel = txnResp.data[0].billpaymentChannel || txnResp.data[0].billpaymentChannelName;
190|            if (channel) payment.bank = mapChannelToBank(channel);
191|          }
192|        } catch (e) {
193|          console.warn('Failed to fetch bank info (webhook):', e.message);
194|        }
195|
196|        await payment.save();
197|
198|        const fee = await Fee.findById(payment.fee);
199|        if (fee && fee.feeStatus !== 'paid') {
200|          const remaining = fee.feeAmount - fee.paidAmount;
201|          const actualAmount = Math.min(payment.paymentAmount, remaining);
202|          await Fee.findOneAndUpdate(
203|            { _id: payment.fee },
204|            {
205|              $inc: { paidAmount: actualAmount },
206|              $set: { status: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
207|            }
208|          );
209|        }
210|      } else if (status_id === '3') {
211|        payment.paymentStatus = 'failed';
212|        await payment.save();
213|      }
214|    }
215|
216|    res.json({ success: true });
217|  } catch (err) {
218|    console.error('FPX webhook error:', err.message);
219|    res.status(500).json({ error: 'Webhook processing failed' });
220|  }
221|});
222|
223|// Check FPX payment status
224|router.get('/fpx/status/:billCode', auth, async (req, res) => {
225|  try {
226|    const payment = await Payment.findOne({ transactionId: req.params.billCode });
227|    if (!payment) return res.status(404).json({ error: 'Payment not found' });
228|    res.json({ status: payment.paymentStatus, payment });
229|  } catch (err) {
230|    res.status(500).json({ error: err.message });
231|  }
232|});
233|
234|// ─── STRIPE (CARD) ───
235|
236|// Create Stripe Checkout Session
237|router.post('/card/create-intent', auth, async (req, res) => {
238|  try {
239|    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
240|    const { feeId, amount } = req.body;
241|    if (!feeId || !mongoose.Types.ObjectId.isValid(feeId)) {
242|      return res.status(400).json({ error: 'Invalid fee ID' });
243|    }
244|    if (!amount || amount <= 0) {
245|      return res.status(400).json({ error: 'Invalid amount' });
246|    }
247|
248|    const fee = await Fee.findById(feeId);
249|    if (!fee) return res.status(404).json({ error: 'Fee not found' });
250|
251|    const appUrl = process.env.APP_URL || 'https://sams-app-vasb.onrender.com';
252|
253|    const session = await stripe.checkout.sessions.create({
254|      payment_method_types: ['card'],
255|      line_items: [{
256|        price_data: {
257|          currency: 'myr',
258|          product_data: { name: 'UMPSA Tuition Fee Payment' },
259|          unit_amount: Math.round(amount * 100),
260|        },
261|        quantity: 1,
262|      }],
263|      mode: 'payment',
264|      success_url: `${appUrl}/api/payment/card/success?session_id={CHECKOUT_SESSION_ID}`,
265|      cancel_url: `${appUrl}/api/payment/card/cancel`,
266|      metadata: { feeId, studentId: req.user.id },
267|    });
268|
269|    // Save pending payment
270|    const payment = new Payment({
271|      student: req.user.id,
272|      fee: feeId,
273|      amount,
274|      method: 'card',
275|      transactionId: session.id,
276|      status: 'pending',
277|    });
278|    await payment.save();
279|
280|    res.json({
281|      paymentUrl: session.url,
282|      sessionId: session.id,
283|      paymentIntentId: session.id,
284|      payment,
285|    });
286|  } catch (err) {
287|    res.status(500).json({ error: err.message });
288|  }
289|});
290|
291|// Stripe success redirect
292|router.get('/card/success', async (req, res) => {
293|  try {
294|    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
295|    const { session_id } = req.query;
296|
297|    const session = await stripe.checkout.sessions.retrieve(session_id);
298|    const payment = await Payment.findOne({ transactionId: session_id });
299|
300|    if (payment && payment.paymentStatus === 'pending' && session.payment_status === 'paid') {
301|      payment.paymentStatus = 'success';
302|      payment.receipt = `RCP-${Date.now()}`;
303|      await payment.save();
304|
305|      const fee = await Fee.findById(payment.fee);
306|      if (fee && fee.feeStatus !== 'paid') {
307|        const remaining = fee.feeAmount - fee.paidAmount;
308|        const actualAmount = Math.min(payment.paymentAmount, remaining);
309|        await Fee.findOneAndUpdate(
310|          { _id: payment.fee },
311|          {
312|            $inc: { paidAmount: actualAmount },
313|            $set: { status: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
314|          }
315|        );
316|      }
317|    }
318|
319|    res.redirect('samsapp://payment/success?session_id=' + session_id);
320|  } catch (err) {
321|    console.error('Stripe success error:', err.message);
322|    res.redirect('samsapp://payment/failed');
323|  }
324|});
325|
326|// Stripe cancel redirect
327|router.get('/card/cancel', (req, res) => {
328|  res.redirect('samsapp://payment/failed');
329|});
330|
331|// Confirm Stripe payment (polling from app)
332|router.post('/card/confirm', auth, async (req, res) => {
333|  try {
334|    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
335|    const { paymentIntentId } = req.body;
336|
337|    const session = await stripe.checkout.sessions.retrieve(paymentIntentId);
338|    const payment = await Payment.findOne({ transactionId: paymentIntentId });
339|
340|    if (!payment) return res.status(404).json({ error: 'Payment not found' });
341|
342|    if (session.payment_status === 'paid') {
343|      if (payment.paymentStatus === 'pending') {
344|        payment.paymentStatus = 'success';
345|        payment.receipt = `RCP-${Date.now()}`;
346|        await payment.save();
347|
348|        const fee = await Fee.findById(payment.fee);
349|        if (fee && fee.feeStatus !== 'paid') {
350|          const remaining = fee.feeAmount - fee.paidAmount;
351|          const actualAmount = Math.min(payment.paymentAmount, remaining);
352|          await Fee.findOneAndUpdate(
353|            { _id: payment.fee },
354|            {
355|              $inc: { paidAmount: actualAmount },
356|              $set: { status: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
357|            }
358|          );
359|        }
360|      }
361|      res.json({ status: 'success', payment });
362|    } else {
363|      res.json({ status: 'pending', payment });
364|    }
365|  } catch (err) {
366|    console.error('Stripe confirm error:', err.message);
367|    res.status(500).json({ error: 'Failed to confirm payment' });
368|  }
369|});
370|
371|// Stripe webhook
372|router.post('/card/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
373|  try {
374|    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
375|    const sig = req.headers['stripe-signature'];
376|    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;
377|
378|    let event;
379|    if (endpointSecret) {
380|      event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
381|    } else {
382|      event = req.body;
383|    }
384|
385|    if (event.type === 'payment_intent.succeeded') {
386|      const paymentIntent = event.data.object;
387|      const payment = await Payment.findOne({ transactionId: paymentIntent.id });
388|      
389|      if (payment && payment.paymentStatus === 'pending') {
390|        payment.paymentStatus = 'success';
391|        payment.receipt = `RCP-${Date.now()}`;
392|        await payment.save();
393|
394|        const fee = await Fee.findById(payment.fee);
395|        if (fee) {
396|          fee.paidAmount += payment.paymentAmount;
397|          fee.feeStatus = fee.paidAmount >= fee.feeAmount ? 'paid' : 'partial';
398|          await fee.save();
399|        }
400|      }
401|    }
402|
403|    res.json({ received: true });
404|  } catch (err) {
405|    res.status(400).json({ error: err.message });
406|  }
407|});
408|
409|// Get Stripe publishable key (for frontend)
410|router.get('/card/config', (req, res) => {
411|  res.json({ publishableKey: process.env.STRIPE_PUBLISHABLE_KEY });
412|});
413|
414|module.exports = router;
415|