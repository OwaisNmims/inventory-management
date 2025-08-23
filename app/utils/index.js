const CC = require('currency-converter-lt')
const cache = {}; // Simple in-memory cache for exchange rates
exports.currencyConverter = (currencyFrom, currencyTo, amount) => {
    let currencyConverter = new CC()


    currencyConverter.rates().then((response) => {
      console.log(response) //or do something else
  })

    console.log('currencyConverter:::::::::',currencyConverter)
        let ratesCacheOptions = {
            isRatesCaching: true, // Set this boolean to true to implement rate caching
            ratesCacheDuration: 3600 // Set this to a positive number to set the number of seconds you want the rates to be cached. Defaults to 3600 seconds (1 hour)
        }
    return new Promise(function(resolve, reject) {    
        // currencyConverter = currencyConverter.setupRatesCache(ratesCacheOptions)
        currencyConverter.from(currencyFrom).to(currencyTo).amount(amount).convert().then((response) => {
            return resolve(response)
        }).catch(err=>{
            return reject('Unable to convert')
        })
    });
};

exports.tourExpenseConverted = async function(result) {
    const array = [];
    for (const item of result) {
      let obj = {
        id: item.id,
        tour_lid: item.tour_lid,
        expense_lid: item.expense_lid,
        expense_type: item.expense_type,
        pax_lid: item.pax_lid,
        pax_type: item.pax_type,
        pax_count: item.pax_count,
        currency_lid: item.currency_lid,
        currency: item.currency,
        total_price: item.total_price,
        unit_price: item.unit_price,
        nightly_recurring: item.nightly_recurring,
        daily_recurring: item.daily_recurring,
        created_at: item.created_at,
        updated_at: item.updated_at,
        created_by: item.created_by,
        updated_by: item.updated_by,
      };
      try {
        if (item.total_price) {
            console.log('HERE1:::::::::::::>>>', item.total_price)
            console.log('HERE2:::::::::::::>>>', Number(item.total_price))
        obj.total_price_inr = await currencyConverter(item.currency, process.env.DEFAULT_CURRENCY, Number(item.total_price))
        console.log('HERE:::::::::::::>>>', obj.total_price_inr)
        } else {
          obj.total_price_inr = '';
        }
      } catch (error) {
        console.error('Error getting S3 public URL:', error);
        obj.total_price = ''; // Set a default value in case of error
      }
      array.push(obj);
    }
    return array;
  };


  async function currencyConverter(currencyFrom, currencyTo, amount) {
    const rateKey = `${currencyFrom}_${currencyTo}`;
    // Check if the exchange rate is already cached
    if (cache[rateKey]) {
        const exchangeRate = cache[rateKey];
        const convertedAmount = amount * exchangeRate;
        return Promise.resolve(convertedAmount);
    }
    // If not cached, fetch the exchange rate and cache it
    const currencyConverter = new CC();
    try {
        const exchangeRate = await currencyConverter.from(currencyFrom).to(currencyTo).convert();
        cache[rateKey] = exchangeRate;
        const convertedAmount = amount * exchangeRate;
        console.log('convertedAmount', convertedAmount)
        return Promise.resolve(convertedAmount);
    } catch (error) {
        return Promise.reject('Unable to convert');
    }
}



exports.calculateTotalPriceInrSum = (expenses) => {
 if (!Array.isArray(expenses)) {
  throw new Error('Expenses must be an array of objects');
}
const sumTotalPriceInr = expenses.reduce((total, expense) => {
  if (typeof expense.total_price_inr === 'number') {
    return total + expense.total_price_inr;
  } else {
    throw new Error('Invalid total_price_inr property in one or more expense objects');
  }
}, 0);

return sumTotalPriceInr;
};