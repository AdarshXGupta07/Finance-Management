async function loadAnalytics() {
  const res = await fetch('/api/analytics');
  const data = await res.json();

  const months = data.annual.months.map(m => `M${m}`);

  new Chart(document.getElementById('incomeExpenseChart'), {
    type: 'bar',
    data: {
      labels: ['Income', 'Expense'],
      datasets: [{
        label: 'Current Month',
        data: [data.summary.total_income, data.summary.total_expense],
        backgroundColor: ['#198754', '#dc3545']
      }]
    }
  });

  new Chart(document.getElementById('categoryPieChart'), {
    type: 'pie',
    data: {
      labels: data.category.labels,
      datasets: [{
        data: data.category.values,
        backgroundColor: ['#0d6efd', '#fd7e14', '#20c997', '#ffc107', '#dc3545', '#6610f2']
      }]
    }
  });

  new Chart(document.getElementById('monthlyTrendChart'), {
    type: 'line',
    data: {
      labels: months,
      datasets: [
        { label: 'Income Trend', data: data.annual.income, borderColor: '#198754', fill: false },
        { label: 'Expense Trend', data: data.annual.expense, borderColor: '#dc3545', fill: false }
      ]
    }
  });
}

loadAnalytics();
