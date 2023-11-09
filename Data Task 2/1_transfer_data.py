import pandas as pd

# Read the HTML table into a Pandas DataFrame
df1 = pd.read_html('C:\\Users\\huhu\\Desktop\\Code Task\\***_task\\data\\state_chars_text.html')
df2 = pd.read_html('C:\\Users\\huhu\\Desktop\\Code Task\\***_task\\data\\law_firms_donations.html')
df3 = pd.read_html('C:\\Users\\huhu\\Desktop\\Code Task\\***_task\\data\\nonlaw_firms_donations.html')

dfa=df1[0]
dfb=df2[0]
dfc=df3[0]

# Save the DataFrame to a CSV file
dfa.to_csv('C:\\Users\\huhu\\Desktop\\Code Task\\***_task\\data\\state_chars_text.csv', index=False)
dfb.to_csv('C:\\Users\\huhu\\Desktop\\Code Task\\***_task\\data\\law_firms_donations.csv', index=False)
dfc.to_csv('C:\\Users\\huhu\\Desktop\\Code Task\\***_task\\data\\nonlaw_firms_donations.csv', index=False)
