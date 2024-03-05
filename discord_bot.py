import discord
import subprocess
from discord.ext import commands

intents = discord.Intents.all()
bot = commands.Bot(command_prefix='!', intents=intents)

@bot.command(name='stundenplan')
async def stundenplan(ctx, day):
    try:
        result = subprocess.run(['./stundenplanfetch_dc.sh', day], capture_output=True, text=True, check=True)
        output = result.stdout
    except subprocess.CalledProcessError as e:
        output = e.stderr

    await ctx.send(f'\n{output}\n')

bot.run('MTE0ODMxNjI2MTMwMjk0Mzc0OA.GTEtFY.LPshd5-PSkFbzScirpKvdVOlHiNZ5lIIEydhcI')
