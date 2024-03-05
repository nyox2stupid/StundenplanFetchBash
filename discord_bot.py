import discord
from discord.ext import commands
import subprocess

# Define your bot's command prefix
bot = commands.Bot(command_prefix='!')

# Define your command
@bot.command(name='stundenplan')
async def stundenplan(ctx, day):
    # Assuming your original script is named 'stundenplanfetch.sh'
    result = subprocess.run(['./stundenplanfetch.sh', day], stdout=subprocess.PIPE, text=True)
    
    # Send the result to the Discord channel
    await ctx.send(f'```\n{result.stdout}\n```')

# Run the bot with your token
bot.run('2o6p1kYrycqiina6DG2CKCUzrg_L-lK3')
